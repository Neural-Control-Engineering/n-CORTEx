function nexAtlas_writePreparedData(spk_in, binPath_in, sessionLabel, subjectDir, sorterTag)
% Write PreparedData.mat + pre-extracted RawWaveforms in UnitMatch format.
% Accepts a single spk struct or cell arrays for multi-trigger sessions.
%
%   spk_in       spk struct  OR  cell array of spk structs (one per trigger)
%   binPath_in   AP binary path  OR  cell array of paths (one per trigger)
%   sessionLabel DTS sessionLabel string
%   subjectDir   fully-resolved subject directory
%   sorterTag    'KS' or 'RT'
%
% Writes:
%   <subjectDir>/npxls/UnitMatch/<sessionLabel>/<sorterTag>/PreparedData.mat
%   <subjectDir>/npxls/UnitMatch/<sessionLabel>/<sorterTag>/RawWaveforms/Unit<id>_RawSpikes.npy
%
% For multi-trigger sessions, waveforms are pooled across all triggers
% (sampleamount/nTriggers spikes per unit per trigger) so UnitMatch sees
% richer templates without overwriting from successive triggers.

    % Coerce scalar inputs to cell arrays
    if ~iscell(spk_in)
        spk_list     = {spk_in};
        binPath_list = {char(binPath_in)};
    else
        spk_list     = spk_in;
        binPath_list = cellfun(@char, binPath_in, 'UniformOutput', false);
    end
    nTriggers = numel(spk_list);

    % binPath_list paths are stored without \\?\ prefix so that dir() and
    % isfile() work correctly (both handle long paths via LongPathsEnabled).
    % The \\?\ prefix is applied only at the memmapfile() call inside
    % extractRawWaveforms, which needs it to open files via CreateFileW.

    outDir = fullfile(subjectDir, 'npxls', 'UnitMatch', char(sessionLabel), char(sorterTag));
    if ~isfolder(outDir), mkdir(outDir); end
    wfDir = fullfile(outDir, 'RawWaveforms');
    if ~isfolder(wfDir), mkdir(wfDir); end

    % Merge spike-level fields across triggers for PreparedData
    spk    = mergeSpkList_public(spk_list);
    nUnits = numel(spk.unit_ids);

    % sp: field names must match UnitMatch's ExtractAndSaveAverageWaveforms
    sp.st             = spk.spike_times_s(:);
    sp.spikeTemplates = spk.spike_clusters(:);
    sp.spikeAmps      = spk.spike_amplitudes(:);
    [~, clus_idx]     = ismember(spk.spike_clusters, spk.unit_ids);
    sp.spikeDepths    = double(spk.unit_locs(clus_idx, 2));
    sp.sample_rate    = double(spk.fs);
    sp.SessionID      = ones(numel(spk.spike_times_s), 1);

    qual = lower(string(spk.unit_quality(:)));
    clusinfo.cluster_id = double(spk.unit_ids(:));
    clusinfo.Good_ID    = double(qual == "good" | qual == "mua");
    clusinfo.RecSesID   = ones(nUnits, 1);
    clusinfo.depth      = double(spk.unit_locs(:, 2));
    clusinfo.ch         = double(spk.unit_root_elecs(:));
    clusinfo.Shank      = zeros(nUnits, 1);
    clusinfo.ProbeID    = zeros(nUnits, 1);

    SessionParams.RunQualityMetrics      = 0;
    SessionParams.RunPyKSChronicStitched = 0;
    SessionParams.AllChannelPos          = {spk.channel_positions};
    SessionParams.AllProbeSN             = {'000000'};
    SessionParams.KSDir                  = {char(outDir)};
    SessionParams.RawDataPaths           = {[]};
    SessionParams.nSyncChans             = 0;
    SessionParams.spikeWidth             = spk.n_wf;

    save(fullfile(outDir, 'PreparedData.mat'), 'sp', 'clusinfo', 'SessionParams', '-v7.3');
    fprintf('[nexAtlas_writePreparedData] PreparedData.mat: %d units, %d trigger(s) → %s\n', ...
        nUnits, nTriggers, outDir);

    extractRawWaveforms(spk_list, binPath_list, wfDir);

    if isempty(dir(fullfile(wfDir, 'Unit*.npy')))
        error('nexAtlas_writePreparedData:emptyWaveforms', ...
            'RawWaveforms came up empty for %s / %s — check binary paths and trigger collection.\nwfDir: %s', ...
            sessionLabel, sorterTag, wfDir);
    end

    % Compress RawWaveforms/ → RawWaveforms.7z (LZMA2 level 1, multithreaded).
    sevenZip    = 'C:\Program Files\7-Zip\7z.exe';
    archivePath = fullfile(outDir, 'RawWaveforms.7z');
    npyFiles    = dir(fullfile(wfDir, 'Unit*.npy'));
    if ~isempty(npyFiles) && isfile(sevenZip)
        items = cellfun(@(f,d) fullfile(d,f), {npyFiles.name}, {npyFiles.folder}, 'UniformOutput', false);
        try
            sevenZipArchive(sevenZip, archivePath, items);
            try, rmdir(wfDir); catch, end
            fprintf('[nexAtlas_writePreparedData] compressed %d .npy files: %s\n', numel(items), archivePath);
        catch e
            fprintf('[nexAtlas_writePreparedData] compression failed, leaving uncompressed:\n%s\n', e.message);
        end
    elseif ~isfile(sevenZip)
        fprintf('[nexAtlas_writePreparedData] 7-zip not found — RawWaveforms left uncompressed.\n');
    end

    fprintf('[nexAtlas_writePreparedData] done: %s / %s\n', sessionLabel, sorterTag);
end

% ── private ───────────────────────────────────────────────────────────────────

function spk = mergeSpkList_public(spk_list)
% Concatenate spike-level fields across triggers.
% Per-unit metadata is unioned across triggers so units that only appear
% in later triggers are not silently dropped.
    spk = spk_list{1};
    for t = 2:numel(spk_list)
        s = spk_list{t};
        spk.spike_times_s    = [spk.spike_times_s(:);    s.spike_times_s(:)];
        spk.spike_clusters   = [spk.spike_clusters(:);   s.spike_clusters(:)];
        spk.spike_amplitudes = [spk.spike_amplitudes(:); s.spike_amplitudes(:)];
        new_mask = ~ismember(s.unit_ids, spk.unit_ids);
        if any(new_mask)
            new_pos  = find(new_mask);
            spk.unit_ids         = [spk.unit_ids(:);         s.unit_ids(new_mask)];
            spk.unit_locs        = [spk.unit_locs;           s.unit_locs(new_mask, :)];
            spk.unit_quality     = [spk.unit_quality(:);     s.unit_quality(new_mask)];
            spk.unit_root_elecs  = [spk.unit_root_elecs(:);  s.unit_root_elecs(new_mask)];
            valid_t  = new_pos(new_pos <= size(s.unit_templates,   1));
            n_fill   = numel(new_pos) - numel(valid_t);
            spk.unit_templates   = cat(1, spk.unit_templates, ...
                s.unit_templates(valid_t, :, :), ...
                zeros(n_fill, size(spk.unit_templates,2),   size(spk.unit_templates,3),   'like', spk.unit_templates));
            valid_s  = new_pos(new_pos <= size(s.spatial_profiles, 1));
            n_fill   = numel(new_pos) - numel(valid_s);
            spk.spatial_profiles = [spk.spatial_profiles; ...
                s.spatial_profiles(valid_s, :); ...
                zeros(n_fill, size(spk.spatial_profiles,2), 'like', spk.spatial_profiles)];
        end
    end
end

function extractRawWaveforms(spk_list, binPath_list, wfDir)
% Extract split-half averaged waveforms pooled across all triggers.
% Opens each trigger binary once via memmapfile (lazy — pages loaded on access).
% Collects ceil(sampleamount/nTriggers) spikes per unit per trigger so total
% stays bounded at sampleamount regardless of trigger count.
%
% Output shape per unit: (spikeWidth × nChans × 2) — [first_half, second_half].

    nTriggers    = numel(spk_list);
    spk0         = spk_list{1};
    spikeWidth   = spk0.n_wf;
    nChans       = spk0.n_chans;
    fs           = double(spk0.fs);
    sampleamount = 1000;
    perTrigger   = ceil(sampleamount / nTriggers);

    if spikeWidth == 61
        baselinewidth = 10;
    else
        baselinewidth = 20;
    end
    waveformwidth = spikeWidth - baselinewidth;

    % Open all trigger binaries up front (lazy memmapfile — no bulk RAM cost)
    mmfs     = cell(nTriggers, 1);
    memDatas = cell(nTriggers, 1);
    nSamples = zeros(nTriggers, 1);
    for t = 1:nTriggers
        bp    = binPath_list{t};
        finfo = dir(bp);   % dir handles long paths; isfile does not with \\?\ prefix
        if isempty(finfo)
            fprintf('[nexAtlas_writePreparedData] binary not found, skipping trigger %d: %s\n', t, bp);
            continue;
        end
        nSaved = nChans + 1;
        if mod(finfo.bytes, nSaved * 2) ~= 0, nSaved = nChans; end
        nSamples(t) = finfo.bytes / (nSaved * 2);
        bp_mm       = strcat('\\?\', bp);   % \\?\ needed for memmapfile/CreateFileW on long paths
        mmfs{t}     = memmapfile(bp_mm, 'Format', {'int16', [nSaved, nSamples(t)], 'data'}, 'Writable', false);
        memDatas{t} = mmfs{t}.Data.data;
    end

    % Union of unit IDs across triggers — a unit active in only one trigger
    % still gets waveforms extracted from that trigger's binary.
    unit_ids = spk0.unit_ids;
    for t = 2:nTriggers
        unit_ids = union(unit_ids, spk_list{t}.unit_ids);
    end

    fprintf('[nexAtlas_writePreparedData] extracting RawWaveforms: %d units, %d trigger(s)...\n', ...
        numel(unit_ids), nTriggers);

    for u = 1:numel(unit_ids)
        uid   = unit_ids(u);
        fname = fullfile(wfDir, sprintf('Unit%d_RawSpikes.npy', uid));
        if isfile(fname), continue; end

        spikeMapAll = zeros(spikeWidth, nChans, 0, 'single');

        for t = 1:nTriggers
            if isempty(memDatas{t}), continue; end
            spk         = spk_list{t};
            spk_samps   = round(spk.spike_times_s * fs);
            mask        = spk.spike_clusters == uid;
            samps       = spk_samps(mask);
            valid       = samps > baselinewidth & (samps + waveformwidth) < nSamples(t);
            samps       = samps(valid);
            if isempty(samps), continue; end

            if numel(samps) > perTrigger
                samps = samps(round(linspace(1, numel(samps), perTrigger)));
            end

            nSpk     = numel(samps);
            spikeBuf = nan(spikeWidth, nChans, nSpk, 'single');
            for si = 1:nSpk
                ts  = samps(si);
                raw = double(memDatas{t}(1:nChans, ts-baselinewidth+1 : ts+waveformwidth));
                raw = smoothdata(raw, 2, 'gaussian', 5);
                raw = raw - mean(raw(:, 1:baselinewidth), 2);
                spikeBuf(:, :, si) = single(raw');
            end
            spikeMapAll = cat(3, spikeMapAll, spikeBuf);
        end

        if isempty(spikeMapAll), continue; end

        nTotal = size(spikeMapAll, 3);
        valid_wavs = find(~any(isnan(reshape(spikeMapAll, spikeWidth*nChans, nTotal)), 1));
        nwavs      = numel(valid_wavs);

        wfOut = nan(spikeWidth, nChans, 2, 'single');
        if nwavs >= 2
            h            = floor(nwavs / 2);
            wfOut(:,:,1) = median(spikeMapAll(:, :, valid_wavs(1:h)),       3, 'omitnan');
            wfOut(:,:,2) = median(spikeMapAll(:, :, valid_wavs(h+1:nwavs)), 3, 'omitnan');
        elseif nwavs == 1
            wfOut(:,:,1) = spikeMapAll(:, :, valid_wavs(1));
            wfOut(:,:,2) = spikeMapAll(:, :, valid_wavs(1));
        end

        writeNPY(wfOut, fname);
    end

    % Release memmapfiles
    for t = 1:nTriggers
        memDatas{t} = [];
        mmfs{t}     = [];
    end
    clear memDatas mmfs;
    fprintf('[nexAtlas_writePreparedData] RawWaveforms done.\n');
end
