function nexAtlas_writePreparedData(spk, rawBinPath, sessionLabel, subjectDir, sorterTag)
% Write PreparedData.mat + pre-extracted RawWaveforms in UnitMatch format.
% Call from extractRAW_NPXLS after sorting, while the raw AP binary is on disk.
%
%   spk          spk_struct from loadKS4_spk or loadRTSort_spk
%   rawBinPath   full path to the raw AP .bin file
%   sessionLabel DTS sessionLabel string
%   subjectDir   fully-resolved subject directory
%   sorterTag    'KS' or 'RT'
%
% Writes:
%   <subjectDir>/npxls/UnitMatch/<sessionLabel>/<sorterTag>/PreparedData.mat
%   <subjectDir>/npxls/UnitMatch/<sessionLabel>/<sorterTag>/RawWaveforms/Unit<id>_RawSpikes.npy
%
% UnitMatch skips its own binary extraction step when Unit*_RawSpikes.npy
% files are already present (RedoExtraction defaults to 0). This is the
% mechanism that makes async UnitMatch calls viable: all waveform data is
% captured here while the raw binary is still on disk.

    % prefix long file path ("\\?\")
    if ispc
        rawBinPath = strcat("\\?\",rawBinPath);
    end

    outDir = fullfile(subjectDir, 'npxls', 'UnitMatch', char(sessionLabel), char(sorterTag));
    if ~isfolder(outDir), mkdir(outDir); end
    wfDir = fullfile(outDir, 'RawWaveforms');
    if ~isfolder(wfDir), mkdir(wfDir); end

    nUnits = numel(spk.unit_ids);

    % sp: field names must match UnitMatch's ExtractAndSaveAverageWaveforms
    % and AssignUniqueIDAlgorithm (sp.st, sp.spikeTemplates, sp.SessionID).
    sp.st             = spk.spike_times_s(:);
    sp.spikeTemplates = spk.spike_clusters(:);          % 1-indexed, matches clusinfo.cluster_id
    sp.spikeAmps      = spk.spike_amplitudes(:);
    sp.spikeDepths    = double(spk.unit_locs(spk.spike_clusters, 2));  % depth per spike
    sp.sample_rate    = double(spk.fs);
    sp.SessionID      = ones(numel(spk.spike_times_s), 1);

    % clusinfo: per-unit metadata consumed by UnitMatch
    qual = lower(string(spk.unit_quality(:)));
    clusinfo.cluster_id = double(spk.unit_ids(:));
    clusinfo.Good_ID    = double(qual == "good" | qual == "mua");
    clusinfo.RecSesID   = ones(nUnits, 1);
    clusinfo.depth      = double(spk.unit_locs(:, 2));
    clusinfo.ch         = double(spk.unit_root_elecs(:));
    clusinfo.Shank      = zeros(nUnits, 1);
    clusinfo.ProbeID    = zeros(nUnits, 1);

    % SessionParams: read by UnitMatch when checking whether PreparedData is
    % current. Also carries metadata used by nexAtlas_runUnitMatch.
    SessionParams.RunQualityMetrics      = 0;
    SessionParams.RunPyKSChronicStitched = 0;
    SessionParams.AllChannelPos          = {spk.channel_positions};  % (nChans × 2)
    SessionParams.AllProbeSN             = {'000000'};
    SessionParams.KSDir                  = {char(outDir)};
    SessionParams.RawDataPaths           = {[]};    % binary not needed; waveforms pre-extracted
    SessionParams.nSyncChans             = 0;       % sync already excluded in our channel layout
    SessionParams.spikeWidth             = spk.n_wf;

    save(fullfile(outDir, 'PreparedData.mat'), 'sp', 'clusinfo', 'SessionParams', '-v7.3');
    fprintf('[nexAtlas_writePreparedData] PreparedData.mat: %d units → %s\n', nUnits, outDir);

    extractRawWaveforms(spk, rawBinPath, wfDir);
    fprintf('[nexAtlas_writePreparedData] done: %s / %s\n', sessionLabel, sorterTag);
end

% ── private ───────────────────────────────────────────────────────────────────

function extractRawWaveforms(spk, rawBinPath, wfDir)
% Extract split-half averaged waveforms per unit and write as
% RawWaveforms/Unit<id>_RawSpikes.npy in the shape UnitMatch expects:
%   (spikeWidth × nChans × 2)  where dim 3 = [first_half, second_half].
%
% UnitMatch checks for these files and skips its own extraction when found.

    if ~isfile(rawBinPath)
        fprintf('[nexAtlas_writePreparedData] binary not found, skipping waveform extraction\n');
        return;
    end

    spikeWidth = spk.n_wf;
    nChans     = spk.n_chans;      % physical AP channels (sync already excluded)
    fs         = double(spk.fs);

    % KS4 uses a shorter baseline window (10 samples); KS2 / RTSort use 20.
    if spikeWidth == 61
        baselinewidth = 10;
    else
        baselinewidth = 20;
    end
    waveformwidth = spikeWidth - baselinewidth;

    % SpikeGLX AP binary: typically nChans + 1 sync channel.
    % Validate by checking divisibility; fall back to nChans if no sync.
    finfo       = dir(rawBinPath);
    nSaved      = nChans + 1;
    if mod(finfo.bytes, nSaved * 2) ~= 0
        nSaved  = nChans;
    end
    n_samples   = finfo.bytes / (nSaved * 2);

    mmf         = memmapfile(rawBinPath, 'Format', {'int16', [nSaved, n_samples], 'data'}, 'Writable', false);
    memData     = mmf.Data.data;

    sampleamount  = 1000;
    spike_samples = round(spk.spike_times_s * fs);

    fprintf('[nexAtlas_writePreparedData] extracting RawWaveforms for %d units...\n', numel(spk.unit_ids));
    for u = 1:numel(spk.unit_ids)
        uid   = spk.unit_ids(u);
        fname = fullfile(wfDir, sprintf('Unit%d_RawSpikes.npy', uid));
        if isfile(fname), continue; end

        mask  = spk.spike_clusters == uid;
        samps = spike_samples(mask);
        valid = samps > baselinewidth & (samps + waveformwidth) < n_samples;
        samps = samps(valid);
        if isempty(samps), continue; end

        if numel(samps) > sampleamount
            samps = samps(round(linspace(1, numel(samps), sampleamount)));
        end
        nSpk = numel(samps);

        spikeMap = nan(spikeWidth, nChans, nSpk, 'single');
        for si = 1:nSpk
            t   = samps(si);
            raw = double(memData(1:nChans, t-baselinewidth+1 : t+waveformwidth));  % (nChans × spikeWidth)
            raw = smoothdata(raw, 2, 'gaussian', 5);
            raw = raw - mean(raw(:, 1:baselinewidth), 2);  % baseline subtract
            spikeMap(:, :, si) = single(raw');             % (spikeWidth × nChans)
        end

        % Valid waveforms: no NaN in any channel or timepoint
        valid_wavs = find(~any(isnan(reshape(spikeMap, spikeWidth * nChans, nSpk)), 1));
        nwavs      = numel(valid_wavs);

        wfOut = nan(spikeWidth, nChans, 2, 'single');
        if nwavs >= 2
            h            = floor(nwavs / 2);
            wfOut(:,:,1) = median(spikeMap(:, :, valid_wavs(1:h)),      3, 'omitnan');
            wfOut(:,:,2) = median(spikeMap(:, :, valid_wavs(h+1:nwavs)), 3, 'omitnan');
        elseif nwavs == 1
            wfOut(:,:,1) = spikeMap(:, :, valid_wavs(1));
            wfOut(:,:,2) = spikeMap(:, :, valid_wavs(1));
        end

        writeNPY(wfOut, fname);
    end

    clear memData mmf;
    fprintf('[nexAtlas_writePreparedData] RawWaveforms done.\n');
end
