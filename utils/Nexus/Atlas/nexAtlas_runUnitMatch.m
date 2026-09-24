function ok = nexAtlas_runUnitMatch(subjectDir, sorterTag, progressFcn)
% Run UnitMatch across all sessions for one subject + sorter,
% then write global_ids into ephys_atlas.h5.
%
%   subjectDir  fully-resolved subject directory
%   sorterTag   'KS' or 'RT'
%   ok          true only if UnitMatch actually ran and results were
%               written. Every failure/nothing-to-do path here reports
%               itself (fprintf + progressFcn) and returns normally rather
%               than throwing — callers MUST check ok rather than assume
%               success just because this returned without an exception.
%   progressFcn optional @(frac, stageLabel) callback, frac in [0,1] —
%               called at real checkpoints only (decompression and result-
%               write loops). The UnitMatch(...) call itself is a single
%               opaque blocking call with no progress hooks of its own —
%               MATLAB is single-threaded, so nothing can animate a bar
%               *during* that call regardless of how progressFcn is
%               wired; it gets exactly one "started" call before and one
%               "finished" call after, honestly reflecting that there's
%               no finer-grained visibility into it.
%
% Prerequisites:
%   - PreparedData.mat + RawWaveforms/ written per session via
%     nexAtlas_writePreparedData (waveforms pre-extracted; no raw binary needed).
%     Sessions missing this are EXCLUDED from the run (reported, not fatal)
%     — UnitMatch itself runs on whichever sessions remain, as long as at
%     least 2 do.
%   - UnitMatch on MATLAB path (utils/UnitMatch/MATLAB)
%
% Writes into ephys_atlas.h5:
%   /units/sessions/<sessionLabel>/<sorterTag>/global_ids   (n_units,)
%   /units/sessions/<sessionLabel>/<sorterTag>/local_ids    (n_units,)

    if nargin < 3 || isempty(progressFcn), progressFcn = @(varargin) []; end
    ok = false;

    umRootDir = fullfile(subjectDir, 'npxls', 'UnitMatch');
    if ~isfolder(umRootDir)
        fprintf('[nexAtlas_runUnitMatch] no UnitMatch folder: %s\n', umRootDir);
        progressFcn(0, 'No UnitMatch folder found.');
        return;
    end

    % Locate PreparedData.mat files for this sorter
    pattern   = fullfile(umRootDir, '*', char(sorterTag), 'PreparedData.mat');
    dataFiles = dir(pattern);
    if isempty(dataFiles)
        fprintf('[nexAtlas_runUnitMatch] no PreparedData.mat found for %s\n', sorterTag);
        progressFcn(0, 'No PreparedData.mat found.');
        return;
    end
    nSess = numel(dataFiles);
    progressFcn(0.02, sprintf('Found %d session(s).', nSess));

    sessionLabels = cell(nSess, 1);
    KSDirs        = cell(nSess, 1);
    AllChannelPos = cell(nSess, 1);

    clusinfo_all = [];
    for i = 1:nSess
        sortDir          = dataFiles(i).folder;
        sessDir          = fileparts(sortDir);
        sessionLabels{i} = strtrim(sessDir(max(strfind(sessDir, filesep))+1:end));
        KSDirs{i}        = sortDir;

        s = load(fullfile(sortDir, 'PreparedData.mat'), 'clusinfo', 'SessionParams');
        c = s.clusinfo;
        c.RecSesID(:) = i;   % session index for this batch

        AllChannelPos{i} = s.SessionParams.AllChannelPos{1};

        if isempty(clusinfo_all)
            clusinfo_all = c;
        else
            fields = fieldnames(c);
            for fi = 1:numel(fields)
                clusinfo_all.(fields{fi}) = [clusinfo_all.(fields{fi}); c.(fields{fi})];
            end
        end
    end

    % ── Decompress all RawWaveforms archives before UnitMatch ─────────────────
    % UnitMatch reads waveforms from all sessions in one batch call, so all
    % sessions must be fully decompressed before UnitMatch fires. Done here,
    % before param/clusinfo_all get filtered down below, since decompression
    % is what determines which sessions actually end up usable.
    sevenZip          = resolveSevenZip_();
    decompressedDirs  = {};
    if isfile(sevenZip)
        for i = 1:nSess
            progressFcn(0.05 + 0.2*(i-1)/nSess, sprintf('Decompressing session %d/%d...', i, nSess));
            archive = fullfile(KSDirs{i}, 'RawWaveforms.7z');
            if isfile(archive)
                wfDir = fullfile(KSDirs{i}, 'RawWaveforms');
                if ~isfolder(wfDir), mkdir(wfDir); end
                sevenZipExtract(sevenZip, archive, wfDir);
                % Delete the archive now, not just at final cleanup — while
                % both RawWaveforms.7z and RawWaveforms/ exist side by side,
                % UnitMatch's own ExtractAndSaveAverageWaveforms.m globs
                % dir([KSDir '/**/RawWaveforms*']), gets 2 matches instead
                % of 1, and can pick the archive file instead of the folder.
                if isfile(archive), delete(archive); end
                decompressedDirs{end+1} = KSDirs{i}; %#ok<AGROW>
            end
        end
        fprintf('[nexAtlas_runUnitMatch] decompressed %d session(s)\n', numel(decompressedDirs));
    end
    progressFcn(0.25, 'Decompression done.');
    % Recompress on any exit — normal return or error
    cleanupObj = onCleanup(@() recompressWaveforms(sevenZip, decompressedDirs)); %#ok<NASGU>

    % ── Drop sessions with incomplete extracted waveforms, run on what's
    % left ─────────────────────────────────────────────────────────────────
    % A session with neither a RawWaveforms.7z archive nor an already-
    % decompressed RawWaveforms/ folder has nothing for UnitMatch to read.
    % UnitMatch's own ExtractAndSaveAverageWaveforms.m correctly detects
    % this and falls back to extracting straight from raw .bin data — but
    % this wrapper deliberately never sets param.RawDataPaths (the whole
    % pipeline assumes pre-extracted waveforms), so that fallback hits
    % dir([]) on an empty AllDecompPaths entry deep inside the toolbox and
    % throws an opaque "Name must be a text scalar." Checking that the
    % folder merely isn't EMPTY isn't enough — a session can have some
    % units extracted and others not (partial/interrupted extraction), and
    % ExtractAndSaveAverageWaveforms.m hits the exact same failure for any
    % single missing unit even in an otherwise-populated session. So check
    % every unit's own file, named exactly as that function names it
    % (Unit<cluster_id>_RawSpikes.npy). Rather than let that happen (or
    % hard-abort the whole run over a subset of sessions), exclude the
    % affected sessions and proceed with whatever remains — reported
    % clearly either way.
    hasWaveforms = false(nSess, 1);
    for i = 1:nSess
        wfDir = fullfile(KSDirs{i}, 'RawWaveforms');
        if ~isfolder(wfDir), continue; end
        sessClusterIDs = clusinfo_all.cluster_id(clusinfo_all.RecSesID == i);
        hasWaveforms(i) = all(arrayfun(@(cid) isfile(fullfile(wfDir, ...
            sprintf('Unit%d_RawSpikes.npy', cid))), sessClusterIDs));
    end
    validIdx        = find(hasWaveforms);
    missingSessions = sessionLabels(~hasWaveforms);
    if ~isempty(missingSessions)
        msg = sprintf(['Excluding %d session(s) with no pre-extracted RawWaveforms: %s.\n' ...
                        '(run nexAtlas_writePreparedData for them, or provide raw .bin paths, ' ...
                        'to include them next time)'], ...
                       numel(missingSessions), strjoin(missingSessions, ', '));
        fprintf('[nexAtlas_runUnitMatch] %s\n', msg);
        progressFcn(0.25, msg);
    end
    if numel(validIdx) < 2
        msg = sprintf(['Only %d session(s) have extracted waveforms — UnitMatch needs at ' ...
                        'least 2 to match units across sessions. Aborting.'], numel(validIdx));
        fprintf('[nexAtlas_runUnitMatch] %s\n', msg);
        progressFcn(0.25, msg);
        return;
    end

    % Re-index everything onto the surviving sessions — UnitMatch addresses
    % sessions positionally (KSDir{i}/AllChannelPos{i}), so RecSesID has to
    % be remapped to stay contiguous 1..numel(validIdx), not just filtered.
    oldToNew            = zeros(1, nSess);
    oldToNew(validIdx)  = 1:numel(validIdx);
    keepUnitMask        = ismember(clusinfo_all.RecSesID, validIdx);
    fields              = fieldnames(clusinfo_all);
    for fi = 1:numel(fields)
        clusinfo_all.(fields{fi}) = clusinfo_all.(fields{fi})(keepUnitMask, :);
    end
    % oldToNew is a row vector — indexing into it returns a result shaped
    % like oldToNew itself, not like clusinfo_all.RecSesID, regardless of
    % RecSesID's own orientation (a MATLAB vector-indexing quirk hit
    % earlier this session too). Left unreshaped, this silently flips a
    % column RecSesID into a row, which propagates into UnitMatch.m's own
    % SessionSwitch computation and breaks its vertcat at line ~95.
    origShape = size(clusinfo_all.RecSesID);
    clusinfo_all.RecSesID = reshape(oldToNew(clusinfo_all.RecSesID), origShape);

    sessionLabels = sessionLabels(validIdx);
    KSDirs        = KSDirs(validIdx);
    AllChannelPos = AllChannelPos(validIdx);
    nSess         = numel(validIdx);

    % spikeWidth: read from first (surviving) session's SessionParams; must
    % match RawWaveforms shape
    sp0 = load(fullfile(KSDirs{1}, 'PreparedData.mat'), 'SessionParams');
    spikeWidth = sp0.SessionParams.spikeWidth;

    % ── Mirror waveforms as double for UnitMatch, without touching the
    % archival single-precision files ───────────────────────────────────────
    % Our RawSpikes.npy files are single (deliberately, for disk space).
    % UnitMatch's own ExtractParameters.m calls lsqcurvefit with data read
    % straight from these files without casting; on this MATLAB/
    % Optimization Toolbox version, lsqcurvefit requires double and throws
    % on single — a throw the toolbox's own fit-failure try/catch silently
    % swallows, turning every unit's spatial-decay fit into NaN and (via an
    % unguarded downstream clamp) every unit's centroid into NaN, which is
    % why matching finds zero candidate pairs. Rather than edit that
    % vendored file, or permanently store waveforms as double, mirror each
    % session's already-decompressed RawWaveforms into a scratch directory
    % as double and point UnitMatch at the mirror. The real archive
    % (single-precision, recompressed at the end via cleanupObj above) is
    % never modified, not even transiently.
    matchKSDirs = cell(nSess, 1);
    mirrorRoot  = tempname();
    mkdir(mirrorRoot);
    cleanupMirror = onCleanup(@() rmdir(mirrorRoot, 's')); %#ok<NASGU>
    progressFcn(0.3, 'Preparing double-precision waveform copies for UnitMatch...');
    for i = 1:nSess
        srcWfDir = fullfile(KSDirs{i}, 'RawWaveforms');
        dstDir   = fullfile(mirrorRoot, sprintf('sess%d', i));
        dstWfDir = fullfile(dstDir, 'RawWaveforms');
        mkdir(dstWfDir);
        npyFiles = dir(fullfile(srcWfDir, 'Unit*_RawSpikes.npy'));
        for k = 1:numel(npyFiles)
            w = readNPY(fullfile(npyFiles(k).folder, npyFiles(k).name));
            writeNPY(double(w), fullfile(dstWfDir, npyFiles(k).name));
        end
        % AssignUniqueIDAlgorithm's optional ISI-violation refinement (run
        % later, after UnitMatch itself) reopens param.KSDir{i}/PreparedData.mat
        % for spike times — mirror it alongside the waveforms so that step
        % doesn't silently skip itself for lack of a file it expects to find.
        copyfile(fullfile(KSDirs{i}, 'PreparedData.mat'), fullfile(dstDir, 'PreparedData.mat'));
        matchKSDirs{i} = dstDir;
    end

    % param: set required fields then let DefaultParametersUnitMatch fill defaults
    param.KSDir                  = matchKSDirs;
    param.AllChannelPos          = AllChannelPos;
    param.SaveDir                = umRootDir;
    param.nSyncChans             = 0;       % sync excluded in our channel layout
    param.spikeWidth             = spikeWidth;
    param.RedoExtraction         = 0;       % use pre-extracted RawWaveforms
    param.RunPyKSChronicStitched = 0;
    param.GoodUnitsOnly          = false;   % include all units; filter externally
    param.RawDataPaths           = repmat({[]}, 1, nSess);

    param = DefaultParametersUnitMatch(param);

    % DefaultParametersUnitMatch always infers Kilosortversion from KSDir string.
    % Our dirs don't contain 'KS4' so it defaults to 2. Override from spikeWidth.
    if spikeWidth == 61
        param.Kilosortversion = 4;
        param.NewPeakLoc      = 22;
        param.waveidx         = 15:32;
    else
        param.Kilosortversion = 2;
        param.NewPeakLoc      = floor(spikeWidth / 2);
        param.waveidx         = param.NewPeakLoc-7 : param.NewPeakLoc+15;
    end

    fprintf('[nexAtlas_runUnitMatch] %s / %s — %d session(s), %d unit(s) total\n', ...
        subjectDir, sorterTag, nSess, numel(clusinfo_all.cluster_id));

    % One opaque blocking call — see the progressFcn doc comment above for
    % why this can only be a before/after pair, not a live-updating span.
    progressFcn(0.35, 'Running UnitMatch — no fine-grained progress available for this step, can take a while.');
    try
        [UniqueIDConversion, MatchTable, ~, ~] = UnitMatch(clusinfo_all, param);
    catch e
        % Full stack, not just e.message — this fires deep inside the
        % UnitMatch toolbox itself, and the bare message alone doesn't say
        % which internal concatenation/line actually failed.
        fprintf('[nexAtlas_runUnitMatch] UnitMatch failed:\n%s\n', getReport(e, 'extended'));
        if any(strcmp({e.stack.name}, 'ApplyNaiveBayes'))
            % Specific, identifiable degenerate case: UnitMatch's own
            % similarity threshold found zero candidate cross-session
            % matches, so CreateNaiveBayes only ever saw one training
            % class ("not a match") and built kernels for it alone.
            % ApplyNaiveBayes then unconditionally indexes a second class
            % that was never built — an array-bounds crash the toolbox
            % doesn't guard against. Surface this as what it actually is
            % (zero matches found) rather than a raw indexing error.
            msg = ['UnitMatch found zero cross-session unit matches above its ' ...
                   'similarity threshold, so its classifier never saw a "match" ' ...
                   'example — this is a real result (or a matching-parameter/' ...
                   'data issue), not a wrapper bug. See the console warnings ' ...
                   'above ("Cannot identify any larger than threshold", ' ...
                   '"No expected matches") and the full stack for detail.'];
        else
            msg = sprintf('UnitMatch failed: %s (see console for full stack)', e.message);
        end
        progressFcn(0.35, msg);
        return;
    end

    % UnitMatch(...) itself NEVER merges matched units' IDs — its own
    % UniqueIDConversion.UniqueID is always the trivial 1:nclus assignment
    % (see UnitMatch.m line 71 and its unconditional save at line ~169;
    % nothing in that file updates UniqueID from MatchProbability). The
    % real merge — turning "unit A in session 3 matched unit B in session
    % 7" into a shared ID — lives entirely in the separate AssignUniqueID
    % function, which the toolbox's own example scripts
    % (FromSpikeGLXToMatching/Helpers/RunUnitMatch.m) call as a distinct
    % step after UnitMatch(...) returns. It reads back the UnitMatch.mat
    % that UnitMatch(...) just saved into param.SaveDir, runs the actual
    % merge algorithm, and overwrites that file with the real result.
    % Skipping this step (as this wrapper originally did) silently writes
    % every unit as its own unique ID, indistinguishable from "no matches
    % found" even when UnitMatch's own MatchProbability matrix shows
    % substantial real cross-session matching.
    progressFcn(0.85, 'Assigning merged cross-session IDs...');
    try
        [UniqueIDConversion, ~, ~] = AssignUniqueID(param.SaveDir);
    catch e
        fprintf('[nexAtlas_runUnitMatch] AssignUniqueID failed:\n%s\n', getReport(e, 'extended'));
        progressFcn(0.85, sprintf('AssignUniqueID failed: %s (see console for full stack)', e.message));
        return;
    end
    progressFcn(0.9, 'UnitMatch finished — writing results...');

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');
    writeUMResults(atlasFile, UniqueIDConversion, sessionLabels, sorterTag, progressFcn);
    fprintf('[nexAtlas_runUnitMatch] done → %s\n', atlasFile);
    progressFcn(1, 'Done.');
    ok = true;
end

% ── private ───────────────────────────────────────────────────────────────────

function writeUMResults(atlasFile, UniqueIDConversion, sessionLabels, sorterTag, progressFcn)
% Write per-session UniqueID assignments into ephys_atlas.h5.
%
% UniqueIDConversion fields (from UnitMatch.m):
%   .UniqueID         (1 × nUnits_all) — cross-session stable ID
%   .OriginalClusID   (1 × nUnits_all) — local cluster_id per unit
%   .recsesAll        (nUnits_all × 1) — recording session index per unit

    nSess = numel(sessionLabels);
    for i = 1:nSess
        progressFcn(0.9 + 0.1*(i-1)/nSess, sprintf('Writing session %d/%d...', i, nSess));
        sessLabel = sessionLabels{i};
        sortKey   = char(sorterTag);
        basePath  = ['/units/sessions/' sessLabel '/' sortKey '/'];

        mask       = UniqueIDConversion.recsesAll == i;
        global_ids = double(UniqueIDConversion.UniqueID(mask))';
        local_ids  = double(UniqueIDConversion.OriginalClusID(mask))';

        writeField(atlasFile, [basePath 'global_ids'], global_ids(:));
        writeField(atlasFile, [basePath 'local_ids'],  local_ids(:));

        fprintf('  session %s: %d units mapped\n', sessLabel, numel(global_ids));
    end
end

function writeField(atlasFile, path, data)
    exists = false;
    try, h5info(atlasFile, path); exists = true; catch, end
    if exists
        nexAtlas_h5overwrite(atlasFile, path, data);
    else
        h5create(atlasFile, path, size(data), 'Datatype', 'double');
        h5write(atlasFile, path, data);
    end
end

function sevenZip = resolveSevenZip_()
% Locate a 7-zip executable for the current platform. Windows keeps the
% original hardcoded install path unchanged. Linux/Mac resolve whichever of
% the common 7-zip binary names is on PATH via `command -v` — returns an
% absolute path (required: isfile() on a bare command name like '7z' would
% not check PATH and always report false). Returns '' if none is found;
% the caller's existing isfile(sevenZip) guard already treats that as
% "decompression unavailable, skip" (same graceful degradation as before,
% now correctly triggered by absence rather than always-wrong-platform).
    if ispc
        sevenZip = 'C:\Program Files\7-Zip\7z.exe';
        return;
    end
    for name = ["7z", "7za", "7zr"]
        [status, out] = system(sprintf('command -v %s', name));
        if status == 0 && ~isempty(strtrim(out))
            sevenZip = strtrim(out);
            return;
        end
    end
    sevenZip = '';
end

function recompressWaveforms(sevenZip, ksDirs)
    for i = 1:numel(ksDirs)
        wfDir    = fullfile(ksDirs{i}, 'RawWaveforms');
        archive  = fullfile(ksDirs{i}, 'RawWaveforms.7z');
        npyFiles = dir(fullfile(wfDir, 'Unit*.npy'));
        if ~isfolder(wfDir) || isempty(npyFiles), continue; end
        if isfile(archive), delete(archive); end
        items = cellfun(@(f,d) fullfile(d,f), {npyFiles.name}, {npyFiles.folder}, 'UniformOutput', false);
        try
            sevenZipArchive(sevenZip, archive, items);
            try, rmdir(wfDir); catch, end
        catch e
            fprintf('[nexAtlas_runUnitMatch] recompression failed for %s:\n%s\n', ksDirs{i}, e.message);
        end
    end
end
