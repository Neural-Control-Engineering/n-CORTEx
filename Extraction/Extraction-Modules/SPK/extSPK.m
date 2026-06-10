function SPK = extSPK(SLRT, npxls_path, trigNum, bin_ms, sigma_ms)
% extSPK  Extract per-trial spike DTS columns from one trigger gate.
%
% SPK = extSPK(SLRT, npxls_path, trigNum)
% SPK = extSPK(SLRT, npxls_path, trigNum, bin_ms, sigma_ms)
%
% npxls_path — path to the sorted trigger folder (contains kilosort4/ and rt_sort/)
% trigNum    — 1-indexed trigger gate number
% bin_ms     — time bin width in ms (default 5)
% sigma_ms   — Gaussian smoothing sigma for spk_rates in ms (default 25)
%
% Output table — one row per trial, columns (sorter-parallel):
%   trial_num, session_label
%   spk_raster_KS,  spk_rates_KS,  spk_amplitudes_KS,
%   spk_spatial_profiles_KS, spk_templates_KS, spk_probe_KS, t_bins_KS
%   spk_raster_RTS, spk_rates_RTS, spk_amplitudes_RTS,
%   spk_spatial_profiles_RTS, spk_templates_RTS, spk_probe_RTS, t_bins_RTS
%   (plus <event>_aligned_t_bins_KS / _RTS for each event signal in SLRT)

    if nargin < 4 || isempty(bin_ms),   bin_ms   = 5;  end
    if nargin < 5 || isempty(sigma_ms), sigma_ms = 25; end

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

    % --- identify event signals from SLRT ---
    events_logical = strcmp(SLRT(1,:).signal_types{1}(:,2), 'event');
    event_signals  = SLRT(1,:).signal_types{1}(events_logical, 1);

    % --- iterate over trials ---
    out = [];
    for trial = 1:size(SLRT, 1)
        trialGate = SLRT(trial,:).("trial-gate"){1};
        if trialGate ~= trigNum, continue; end

        session_label = SLRT(trial,:).session_label{1};
        t_start_s     = SLRT(trial,:).("trial-gate_clock_time"){1}(1);
        t_stop_s      = SLRT(trial,:).("trial-gate_clock_time"){1}(end);
        t_start_ms    = t_start_s * 1000;
        t_stop_ms     = t_stop_s  * 1000;

        row = table(trigNum, {session_label}, ...
            'VariableNames', {'trial_num', 'session_label'});

        % --- KS4 columns ---
        row = addSorterCols(row, spk_ks4, t_start_ms, t_stop_ms, ...
            bin_ms, sigma_ms, 'KS', SLRT, trial, event_signals);

        % --- RTSort columns ---
        row = addSorterCols(row, spk_rts, t_start_ms, t_stop_ms, ...
            bin_ms, sigma_ms, 'RTS', SLRT, trial, event_signals);

        if isempty(out)
            out = row;
        else
            out = [out; row];  %#ok<AGROW>
        end
    end

    SPK = out;
end

% -------------------------------------------------------------------------
function row = addSorterCols(row, spk, t_start_ms, t_stop_ms, ...
        bin_ms, sigma_ms, suffix, SLRT, trial, event_signals)
% Append sorter-specific DTS columns to a trial row.
% If spk is empty (sorter not available), all columns contain empty cells.

    sfx = ['_', suffix];

    if isempty(spk)
        row.(['spk_raster'          sfx]) = {[]};
        row.(['spk_rates'           sfx]) = {[]};
        row.(['spk_amplitudes'      sfx]) = {[]};
        row.(['spk_spatial_profiles' sfx]) = {[]};
        row.(['spk_templates'       sfx]) = {[]};
        row.(['spk_probe'           sfx]) = {[]};
        row.(['t_bins'              sfx]) = {[]};
        for es = 1:numel(event_signals)
            sig = event_signals{es};
            row.([sig '_aligned_t_bins' sfx]) = {[]};
        end
        return;
    end

    dts = formatSpk_toDTS(spk, t_start_ms, t_stop_ms, bin_ms, sigma_ms);

    row.(['spk_raster'           sfx]) = {dts.spk_raster};
    row.(['spk_rates'            sfx]) = {dts.spk_rates};
    row.(['spk_amplitudes'       sfx]) = {dts.spk_amplitudes};
    row.(['spk_spatial_profiles' sfx]) = {dts.spk_spatial_profiles};
    row.(['spk_templates'        sfx]) = {dts.spk_templates};
    row.(['spk_probe'            sfx]) = {dts.spk_probe};
    row.(['t_bins'               sfx]) = {dts.t_bins};

    % event-aligned time vectors (shift t_bins by event offset)
    for es = 1:numel(event_signals)
        sig       = event_signals{es};
        col_name  = [sig '_aligned_t_bins' sfx];
        eventData = SLRT(trial,:).(sig);
        if iscell(eventData), eventData = eventData{1}; end
        if ~isnan(eventData)
            event_time_ms = SLRT(trial,:).("trial-gate_clock_time"){1}(eventData) * 1000;
            aligned_t     = dts.t_bins - (event_time_ms - t_start_ms);
        else
            aligned_t = [];
        end
        row.(col_name) = {aligned_t};
    end
end
