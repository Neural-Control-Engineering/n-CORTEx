function spk = loadRTSort_spk(rtsort_mat_path)
% loadRTSort_spk  Load rtsort_results.mat and return a normalized spk_struct.
%
% spk = loadRTSort_spk(rtsort_mat_path)
%
% rtsort_mat_path — full path to rtsort_results.mat (produced by extract_rtsort)
%
% Returns the same spk_struct schema as loadKS4_spk:
%   spike_times_ms      (N_spikes x 1) — spike times in milliseconds
%   spike_clusters      (N_spikes x 1) — unit index, 1-indexed, contiguous
%   spike_amplitudes    (N_spikes x 1) — peak-to-trough amplitude
%   unit_ids            (N_UNITS x 1)
%   unit_quality        (N_UNITS x 1 cell)
%   unit_locs           (N_UNITS x 2)  — x/y in um (seq_locs)
%   unit_root_elecs     (N_UNITS x 1)  — root channel, 1-indexed
%   unit_templates      (N_UNITS x N_WF x N_CHANS single)
%   spatial_profiles    (N_UNITS x N_CHANS) — from seqs_amps, expanded to full probe
%   channel_positions   (N_CHANS x 2)  — empty (not stored in rtsort_results)
%   n_wf                scalar
%   n_chans             scalar
%   fs                  scalar

    R = load(rtsort_mat_path);

    N_UNITS  = R.N_UNITS;
    N_WF     = R.N_BEFORE + R.N_AFTER + 1;
    N_CHANS  = size(R.mean_templates, 3);
    fs       = R.RAW_SAMP_FREQ;

    % --- flatten spike matrices (NaN-padded columns -> flat vectors) ---
    spike_times_ms   = zeros(0,1);
    spike_clusters   = zeros(0,1,'double');
    spike_amplitudes = zeros(0,1);

    for u = 1:N_UNITS
        n  = R.spike_counts(u);
        st = R.spike_train_mat(1:n, u);       % ms
        amp = R.spike_amp_mat(1:n, u);
        amp(isnan(amp)) = 0;                  % failed extraction -> 0

        spike_times_ms   = [spike_times_ms;   st(:)];        %#ok<AGROW>
        spike_clusters   = [spike_clusters;   repmat(u, n, 1)];  %#ok<AGROW>
        spike_amplitudes = [spike_amplitudes; amp(:)];        %#ok<AGROW>
    end

    % --- spatial profiles: expand seqs_amps (N_UNITS x N_COMP) to full probe ---
    % comp_elecs: (N_COMP x 1) 1-indexed channel indices
    spatial_profiles = zeros(N_UNITS, N_CHANS, 'single');
    if isfield(R, 'seqs_amps') && isfield(R, 'comp_elecs') && ~isempty(R.comp_elecs)
        comp_idx = R.comp_elecs(:)';  % row vector of 1-indexed channel indices
        comp_idx = min(comp_idx, N_CHANS);  % guard against out-of-range
        for u = 1:N_UNITS
            spatial_profiles(u, comp_idx) = single(R.seqs_amps(u, :));
        end
        % normalize each unit to [0,1]
        row_max = max(spatial_profiles, [], 2);
        row_max(row_max == 0) = 1;
        spatial_profiles = spatial_profiles ./ row_max;
    end

    % --- assemble output ---
    spk.spike_times_ms     = spike_times_ms;
    spk.spike_clusters     = spike_clusters;
    spk.spike_amplitudes   = spike_amplitudes;
    spk.unit_ids           = (1:N_UNITS)';
    spk.unit_quality       = R.quality_labels;
    spk.unit_locs          = R.locs;
    spk.unit_root_elecs    = R.root_elecs;
    spk.unit_templates     = R.mean_templates;   % N_UNITS x N_WF x N_CHANS single
    spk.spatial_profiles   = spatial_profiles;
    spk.channel_positions  = zeros(N_CHANS, 2);  % not available from RTSort output
    spk.n_wf               = N_WF;
    spk.n_chans            = N_CHANS;
    spk.fs                 = fs;
end
