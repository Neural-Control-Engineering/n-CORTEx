function SPK = extSPK(SLRT, npxls_path, trigNum, bin_s, sigma_s, doViz)
% extSPK  Extract per-trial spike DTS columns from one trigger gate.
%
% SPK = extSPK(SLRT, npxls_path, trigNum)
% SPK = extSPK(SLRT, npxls_path, trigNum, bin_s, sigma_s)
% SPK = extSPK(SLRT, npxls_path, trigNum, bin_s, sigma_s, doViz)
%
% npxls_path — path to the sorted trigger folder (contains kilosort4/ and rt_sort/)
% trigNum    — 1-indexed trigger gate number
% bin_s      — time bin width in s (default 0.005)
% sigma_s    — Gaussian smoothing sigma for spk_rates in s (default 0.025)
% doViz      — if true, plot the sync drift + per-edge alignment residual to
%              verify the world-clock remap (default false)
%
% Output table — one row per trial. Per sorter S in {KS, RTS}, five DFs named
% <S>_<base>_<stub> (stub = df/unit/t/chans/wf/measure/factor, always the final token):
%   S_spk_activity_df   (unit × t × measure)  + _unit, _t, _measure
%   S_spk_spatial_df    (unit × chan)         + _unit, _chans
%   S_spk_templates_df  (wf × unit)           + _wf, _unit
%   S_spk_probe_df      (t × chan)            + _t, _chans
%   S_spk_units_df      (unit × factor)       + _unit, _factor  [root_elec,loc_x,loc_y]
%   S_spk_units_quality (per-unit quality string, sibling simple column)
% Event alignment is applied on demand by nexOp_eventAlignDF (canonical _t axis
% + stored scalar event indices) — no per-event columns are emitted.

    if nargin < 4 || isempty(bin_s),   bin_s   = 0.005; end
    if nargin < 5 || isempty(sigma_s), sigma_s = 0.025; end
    if nargin < 6 || isempty(doViz),   doViz   = false; end

    ks4_dir   = fullfile(npxls_path, 'kilosort4');
    rts_mat   = fullfile(npxls_path, 'rt_sort', 'rtsort_results.mat');

    have_ks4 = isfolder(ks4_dir);
    have_rts = isfile(rts_mat);

    if ~have_ks4 && ~have_rts
        warning('extSPK: no KS4 or RTSort output found in %s', npxls_path);
        SPK = [];
        return;
    end

    % --- load spike data ---
    spk_ks4 = [];  spk_rts = [];
    if have_ks4
        fprintf('  extSPK: loading KS4 from %s\n', ks4_dir);
        try
            spk_ks4 = loadKS4_spk(ks4_dir);
        catch e
            warning('extSPK: loadKS4_spk failed — %s', e.message);
        end
    end
    if have_rts
        fprintf('  extSPK: loading RTSort from %s\n', rts_mat);
        try
            spk_rts = loadRTSort_spk(rts_mat);
        catch e
            warning('extSPK: loadRTSort_spk failed — %s', e.message);
        end
    end

    % --- cross-device drift correction (mirror extAP / extLFP) ---
    % The 1 Hz sync pulse fed into SLRT drifts slowly relative to the imec
    % acquisition clock over long recordings. loadKS4_spk / loadRTSort_spk
    % return spike_times_s in the imec acquisition clock; here we measure the
    % per-edge offsets against the SLRT reference line and remap spike times
    % onto the SLRT world clock so they bin correctly against trial-gate times.
    t_imec = [];
    try
        load(fullfile(npxls_path, "sync.mat"), 'sync');
        load(fullfile(npxls_path, "ap.mat"),   'ap');
        load(fullfile(npxls_path, "lfp.mat"),  'lfp');
        t_start_meta = str2double(lfp.meta.firstSample) / str2double(lfp.meta.imSampRate); % seconds before gate start
        nSamples = (str2double(ap.meta.fileSizeBytes) / str2double(ap.meta.nSavedChans)) / 2; % 2 bytes/sample
        ap.dataArray = ones([1, nSamples]);
        ap.meta.Fs   = str2double(ap.meta.imSampRate);
        [sync_ref, sessionDetails] = constructSync_slrt(SLRT, trigNum);
        sync.lines.sync_1Hz_imec.t_edges = filterSyncEdges(sync.lines.sync_1Hz_imec.t_edges, ...
            1 / sync.lines.sync_1Hz_imec.Freq);
        sync = extractSyncOffset(sync_ref.lines.sync_1Hz_slrt, sync, t_start_meta);
        t_imec = mapSyncTimeline(ap, sync.lines.sync_1Hz_imec, sync.lines.sync_1Hz_imec.offset0); % world-clock time per imec sample (s)
        if doViz
            vizSyncAlignment_spk(sync.lines.sync_1Hz_imec, t_imec, ap.meta.Fs, ...
                sessionDetails.sessionLabel, trigNum);
        end
    catch e
        warning('extSPK: sync drift correction skipped (%s) — spike times remain in acquisition clock', e.message);
    end

    if ~isempty(t_imec)
        if ~isempty(spk_ks4), spk_ks4 = applySyncOffset_spk(spk_ks4, t_imec); end
        if ~isempty(spk_rts), spk_rts = applySyncOffset_spk(spk_rts, t_imec); end
    end

    % --- iterate over trials ---
    out = [];
    for trial = 1:size(SLRT, 1)
        trialGate = SLRT(trial,:).("trial-gate"){1};
        if trialGate ~= trigNum, continue; end

        session_label = SLRT(trial,:).session_label{1};
        t_start_s     = SLRT(trial,:).("trial-gate_clock_time"){1}(1);
        t_stop_s      = SLRT(trial,:).("trial-gate_clock_time"){1}(end);

        row = table(trigNum, {session_label}, ...
            'VariableNames', {'trial_num', 'session_label'});

        % --- KS4 DFs (prefix KS_) ---
        row = addSorterCols(row, spk_ks4, t_start_s, t_stop_s, bin_s, sigma_s, 'KS');

        % --- RTSort DFs (prefix RTS_) ---
        row = addSorterCols(row, spk_rts, t_start_s, t_stop_s, bin_s, sigma_s, 'RTS');

        if isempty(out)
            out = row;
        else
            out = [out; row];  %#ok<AGROW>
        end
    end

    SPK = out;
end

% -------------------------------------------------------------------------
function row = addSorterCols(row, spk, t_start_s, t_stop_s, bin_s, sigma_s, sorterTag)
% Append one sorter's DFs (+ axis & metadata companions) to a trial row, named
% <sorterTag>_<base>_<stub> so nexus_exportDTS / dtsIO_composeDF route each
% column to the right DF slot. The routing stub (df/unit/t/chans/wf/measure)
% must be the FINAL token, so the sorter tag is a PREFIX, never a suffix.
% Empty cells when the sorter is absent, to keep the schema stable across trials.

    p = [char(sorterTag), '_'];   % column prefix, e.g. 'KS_'

    cols = { ...
        'spk_activity_df','spk_activity_unit','spk_activity_t','spk_activity_measure', ...
        'spk_spatial_df','spk_spatial_unit','spk_spatial_chans', ...
        'spk_templates_df','spk_templates_wf','spk_templates_unit', ...
        'spk_probe_df','spk_probe_t','spk_probe_chans', ...
        'spk_units_df','spk_units_unit','spk_units_factor','spk_units_quality'};

    if isempty(spk)
        for k = 1:numel(cols)
            row.([p cols{k}]) = {[]};
        end
        return;
    end

    dts = formatSpk_toDTS(spk, t_start_s, t_stop_s, bin_s, sigma_s);

    % activity DF  (unit × t × measure)
    row.([p 'spk_activity_df'])      = {dts.activity};
    row.([p 'spk_activity_unit'])    = {dts.ax_unit};
    row.([p 'spk_activity_t'])       = {dts.ax_t};
    row.([p 'spk_activity_measure']) = {dts.ax_measure};
    % spatial DF  (unit × chan)
    row.([p 'spk_spatial_df'])       = {dts.spatial};
    row.([p 'spk_spatial_unit'])     = {dts.ax_unit};
    row.([p 'spk_spatial_chans'])    = {dts.ax_chans};
    % templates DF  (wf × unit)
    row.([p 'spk_templates_df'])     = {dts.templates};
    row.([p 'spk_templates_wf'])     = {dts.ax_wf};
    row.([p 'spk_templates_unit'])   = {dts.ax_unit};
    % probe DF  (t × chan)
    row.([p 'spk_probe_df'])         = {dts.probe};
    row.([p 'spk_probe_t'])          = {dts.ax_t};
    row.([p 'spk_probe_chans'])      = {dts.ax_chans};
    % units metadata DF  (unit × factor = [root_elec, loc_x, loc_y])
    row.([p 'spk_units_df'])         = {dts.units};
    row.([p 'spk_units_unit'])       = {dts.ax_unit};
    row.([p 'spk_units_factor'])     = {dts.ax_factor};
    % unit quality (sibling simple string column, not part of the units DF group)
    row.([p 'spk_units_quality'])    = {dts.unit_quality};
end

% -------------------------------------------------------------------------
function spk = applySyncOffset_spk(spk, t_imec)
% Remap spike times from the imec acquisition clock onto the SLRT world clock.
% spk.spike_times_s = sample/fs, so round(t_s*fs) recovers the acquisition
% sample index; t_imec (built by mapSyncTimeline) holds the drift-corrected
% world-clock time (s) for each imec sample. Mirrors extAP's
% spike_times = t_ap(spike_inds).

    nS  = numel(t_imec);
    idx = round(spk.spike_times_s * spk.fs);          % acquisition sample index
    idx = max(1, min(nS, idx));                       % clamp to valid range
    spk.spike_times_s = t_imec(idx(:))';              % world-clock seconds (column)
end

% -------------------------------------------------------------------------
function vizSyncAlignment_spk(syncLine, t_imec, Fs, sessionLabel, trigNum)
% Optional QC plot to confirm the world-clock remap worked.
%   Top:    the 1 Hz pulse drift (imec vs SLRT) that is being corrected.
%   Bottom: per-edge residual before vs after remap — the "after" trace
%           should collapse onto 0 (imec edges land on the SLRT reference).

    nS = numel(t_imec);

    % drift curve (offset measured at each reference edge)
    m = min(numel(syncLine.t_edges_ref), numel(syncLine.syncOffsets));
    t_ref_drift = syncLine.t_edges_ref(1:m);
    offsets     = syncLine.syncOffsets(1:m);

    % per-edge alignment: remap each imec edge to world clock via t_imec, then
    % pair to the NEAREST reference edge. Nearest-neighbour (not index) pairing
    % is required because extractSyncOffset/measureSyncOffsets trim leading
    % edges, so syncLine.t_edges and t_edges_ref are not index-aligned.
    e_imec = syncLine.t_edges(:);
    e_ref  = syncLine.t_edges_ref(:);
    idx    = max(1, min(nS, round(e_imec * Fs)));   % imec edge -> sample index
    e_corr = t_imec(idx(:));                         % world-clock time of each imec edge (col)
    [~, nn_before] = arrayfun(@(e) min(abs(e - e_ref)), e_imec);
    [~, nn_after ] = arrayfun(@(e) min(abs(e - e_ref)), e_corr);
    res_before = e_imec - e_ref(nn_before);          % raw imec − nearest SLRT edge
    res_after  = e_corr - e_ref(nn_after);           % corrected − nearest SLRT edge

    figure('Name', sprintf('SPK sync alignment — %s trig %d', sessionLabel, trigNum));
    tiledlayout(2,1);

    nexttile;
    plot(t_ref_drift(:), offsets(:), '-o', 'MarkerSize', 3);
    grid on; xlabel('SLRT reference edge time (s)'); ylabel('measured offset (s)');
    title('1 Hz pulse drift being corrected (imec vs SLRT)');

    nexttile;
    plot(e_ref(nn_before), res_before, '-o', 'MarkerSize', 3, ...
        'DisplayName', 'before (raw imec − nearest SLRT)'); hold on;
    plot(e_ref(nn_after),  res_after,  '-o', 'MarkerSize', 3, ...
        'DisplayName', 'after (corrected − nearest SLRT)');
    yline(0, 'k:', 'HandleVisibility', 'off'); hold off;
    grid on; legend('Location', 'best');
    xlabel('nearest SLRT reference edge time (s)'); ylabel('edge residual (s)');
    title('Per-edge alignment residual — "after" should sit on 0');
end


