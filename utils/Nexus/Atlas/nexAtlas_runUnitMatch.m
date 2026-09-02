function nexAtlas_runUnitMatch(subjectDir, sorterTag)
% Run UnitMatch across all sessions for one subject + sorter,
% then write global_ids into ephys_atlas.h5.
%
%   subjectDir  fully-resolved subject directory
%   sorterTag   'KS' or 'RT'
%
% Prerequisites:
%   - PreparedData.mat + RawWaveforms/ written per session via
%     nexAtlas_writePreparedData (waveforms pre-extracted; no raw binary needed)
%   - UnitMatch on MATLAB path (utils/UnitMatch/MATLAB)
%
% Writes into ephys_atlas.h5:
%   /units/sessions/<sessionLabel>/<sorterTag>/global_ids   (n_units,)
%   /units/sessions/<sessionLabel>/<sorterTag>/local_ids    (n_units,)

    umRootDir = fullfile(subjectDir, 'npxls', 'UnitMatch');
    if ~isfolder(umRootDir)
        fprintf('[nexAtlas_runUnitMatch] no UnitMatch folder: %s\n', umRootDir);
        return;
    end

    % Locate PreparedData.mat files for this sorter
    pattern   = fullfile(umRootDir, '*', char(sorterTag), 'PreparedData.mat');
    dataFiles = dir(pattern);
    if isempty(dataFiles)
        fprintf('[nexAtlas_runUnitMatch] no PreparedData.mat found for %s\n', sorterTag);
        return;
    end
    nSess = numel(dataFiles);

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

    % spikeWidth: read from first session's SessionParams; must match RawWaveforms shape
    sp0 = load(fullfile(KSDirs{1}, 'PreparedData.mat'), 'SessionParams');
    spikeWidth = sp0.SessionParams.spikeWidth;

    % param: set required fields then let DefaultParametersUnitMatch fill defaults
    param.KSDir                  = KSDirs;
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

    fprintf('[nexAtlas_runUnitMatch] %s / %s — %d sessions, %d units total\n', ...
        subjectDir, sorterTag, nSess, numel(clusinfo_all.cluster_id));

    % ── Decompress all RawWaveforms archives before UnitMatch ─────────────────
    % UnitMatch reads waveforms from all sessions in one batch call, so all
    % sessions must be fully decompressed before UnitMatch fires.
    sevenZip          = 'C:\Program Files\7-Zip\7z.exe';
    decompressedDirs  = {};
    if isfile(sevenZip)
        for i = 1:nSess
            archive = fullfile(KSDirs{i}, 'RawWaveforms.7z');
            if isfile(archive)
                wfDir = fullfile(KSDirs{i}, 'RawWaveforms');
                if ~isfolder(wfDir), mkdir(wfDir); end
                sevenZipExtract(sevenZip, archive, wfDir);
                decompressedDirs{end+1} = KSDirs{i}; %#ok<AGROW>
            end
        end
        fprintf('[nexAtlas_runUnitMatch] decompressed %d session(s)\n', numel(decompressedDirs));
    end
    % Recompress on any exit — normal return or error
    cleanupObj = onCleanup(@() recompressWaveforms(sevenZip, decompressedDirs)); %#ok<NASGU>

    try
        [UniqueIDConversion, MatchTable, ~, ~] = UnitMatch(clusinfo_all, param);
    catch e
        fprintf('[nexAtlas_runUnitMatch] UnitMatch failed: %s\n', e.message);
        return;
    end

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');
    writeUMResults(atlasFile, UniqueIDConversion, sessionLabels, sorterTag);
    fprintf('[nexAtlas_runUnitMatch] done → %s\n', atlasFile);
end

% ── private ───────────────────────────────────────────────────────────────────

function writeUMResults(atlasFile, UniqueIDConversion, sessionLabels, sorterTag)
% Write per-session UniqueID assignments into ephys_atlas.h5.
%
% UniqueIDConversion fields (from UnitMatch.m):
%   .UniqueID         (1 × nUnits_all) — cross-session stable ID
%   .OriginalClusID   (1 × nUnits_all) — local cluster_id per unit
%   .recsesAll        (nUnits_all × 1) — recording session index per unit

    nSess = numel(sessionLabels);
    for i = 1:nSess
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
