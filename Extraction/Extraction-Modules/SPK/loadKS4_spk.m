function spk = loadKS4_spk(ks4_dir)
% loadKS4_spk  Load Kilosort4 output and return a normalized spk_struct.
%
% spk = loadKS4_spk(ks4_dir)
%
% ks4_dir — path to the kilosort4/ output folder (contains spike_times.npy etc.)
%
% Returns spk_struct with fields:
%   spike_times_s       (N_spikes x 1) — all spike times in seconds
%   spike_clusters      (N_spikes x 1) — unit index, 1-indexed, contiguous
%   spike_amplitudes    (N_spikes x 1) — per-spike KS4 amplitude scalar
%   unit_ids            (N_UNITS x 1)  — 1:N_UNITS
%   unit_quality        (N_UNITS x 1 cell) — 'good' / 'mua' / 'noise'
%   unit_locs           (N_UNITS x 2)  — x/y in um (at root channel)
%   unit_root_elecs     (N_UNITS x 1)  — root channel, PHYSICAL 1-indexed
%   unit_templates      (N_UNITS x N_WF x N_CHANS single) — full physical probe (dropped chans = 0)
%   spatial_profiles    (N_UNITS x N_CHANS) — normalised p2p, full physical probe (dropped chans = 0)
%   channel_positions   (N_CHANS x 2)  — x/y um, full physical probe (dropped chans = NaN)
%   n_wf                scalar — waveform window in samples
%   n_chans             scalar — FULL physical probe width (e.g. 384), not the KS-kept count
%   fs                  scalar — sample rate (Hz)

    fs = 30000;  % Neuropixels AP band default; overridden from ops if present

    % --- load KS4 files ---
    spike_inds    = double(readNPY(fullfile(ks4_dir, 'spike_times.npy')));     % samples
    spike_clust   = double(readNPY(fullfile(ks4_dir, 'spike_clusters.npy')));  % 0-indexed
    amplitudes_ks = double(readNPY(fullfile(ks4_dir, 'amplitudes.npy')));
    templates_all = readNPY(fullfile(ks4_dir, 'templates.npy'));               % (n_tmpl x N_WF x N_CHANS_kept)
    chan_pos      = readNPY(fullfile(ks4_dir, 'channel_positions.npy'));        % (N_CHANS_kept x 2)
    chan_map      = double(readNPY(fullfile(ks4_dir, 'channel_map.npy')));      % physical chan idx of each kept chan (0-indexed)

    cluster_group  = readtable(fullfile(ks4_dir, 'cluster_group.tsv'),  ...
        'FileType','text','Delimiter','\t');
    cluster_amp    = readtable(fullfile(ks4_dir, 'cluster_Amplitude.tsv'), ...
        'FileType','text','Delimiter','\t');

    % --- build unit list from cluster_group (good + mua + noise) ---
    cluster_ids = sort(unique(spike_clust));  % 0-indexed KS4 IDs
    N_UNITS     = numel(cluster_ids);
    N_WF        = size(templates_all, 2);
    N_CHANS     = size(templates_all, 3);   % KS-kept channels (bad/unconnected dropped)

    % Physical-domain channel axis: KS4 sorts only the channels it keeps, so
    % templates/positions span N_CHANS <= the full probe. Per-channel fields are
    % scattered back onto the full physical probe (below) so spatial_profiles /
    % probe / templates have a fixed, session-comparable width and the chans axis
    % is the physical channel index. See KILOSORT_RTSORT_SUBPROCESS.md —
    % "always maintain physical domains, pool across sessions".
    N_CHANS_PROBE = 384;                                 % NP1.0 AP band (physical probe width)
    chan_phys     = chan_map(:)' + 1;                    % 1-indexed physical channel of each kept chan
    N_CHANS_FULL  = max(N_CHANS_PROBE, max(chan_phys));  % guard if probe wider than 384

    % --- remap cluster IDs to 1:N_UNITS ---
    id_map = zeros(max(cluster_ids)+1, 1, 'double');  % KS4_id -> 1-indexed
    for u = 1:N_UNITS
        id_map(cluster_ids(u)+1) = u;
    end
    spike_clusters_remapped = id_map(spike_clust + 1);

    % --- per-unit fields ---
    unit_templates    = zeros(N_UNITS, N_WF, N_CHANS, 'single');
    unit_root_elecs   = zeros(N_UNITS, 1);
    unit_locs         = zeros(N_UNITS, 2);
    unit_quality      = cell(N_UNITS, 1);
    spatial_profiles  = zeros(N_UNITS, N_CHANS, 'single');

    for u = 1:N_UNITS
        ks_id    = cluster_ids(u);  % 0-indexed
        tmpl_idx = ks_id + 1;       % 1-indexed row in templates_all
        tmpl_idx = min(tmpl_idx, size(templates_all, 1));  % guard post-curation overflow

        % KS4 templates.npy is (n_templates x N_WF x N_CHANS), indexed by cluster_id
        tmpl = squeeze(templates_all(tmpl_idx, :, :));  % N_WF x N_CHANS

        % root channel = max peak-to-peak
        p2p = max(tmpl,[],1) - min(tmpl,[],1);   % 1 x N_CHANS
        [~, root_ch] = max(p2p);

        unit_templates(u,:,:)  = single(tmpl);
        unit_root_elecs(u)     = chan_phys(root_ch);  % PHYSICAL 1-indexed channel
        unit_locs(u,:)         = chan_pos(root_ch,:); % physical x/y (already real geometry)
        spatial_profiles(u,:)  = single(p2p / (max(p2p) + 1e-9));

        % quality from cluster_group
        row_q = cluster_group(cluster_group.cluster_id == ks_id, :);
        if ~isempty(row_q)
            lbl = string(row_q.KSLabel(1));
            if lbl == "good"
                unit_quality{u} = 'good';
            elseif lbl == "mua"
                unit_quality{u} = 'mua';
            else
                unit_quality{u} = 'noise';
            end
        else
            unit_quality{u} = 'noise';
        end
    end

    % --- scatter per-channel fields onto the full physical probe ---
    % kept channels go to their physical slots; dropped channels stay 0 (data) /
    % NaN (positions) so the chans axis is the physical channel index, fixed-width
    % across sessions and aligned with the RTSort probe.
    templates_full = zeros(N_UNITS, N_WF, N_CHANS_FULL, 'single');
    templates_full(:, :, chan_phys) = unit_templates;
    spatial_full   = zeros(N_UNITS, N_CHANS_FULL, 'single');
    spatial_full(:, chan_phys)      = spatial_profiles;
    chanpos_full   = nan(N_CHANS_FULL, 2);
    chanpos_full(chan_phys, :)      = chan_pos;

    % --- assemble output ---
    spk.spike_times_s      = spike_inds / fs;         % samples -> seconds
    spk.spike_clusters     = spike_clusters_remapped;
    spk.spike_amplitudes   = amplitudes_ks(:);
    spk.unit_ids           = (1:N_UNITS)';
    spk.unit_quality       = unit_quality;
    spk.unit_locs          = unit_locs;
    spk.unit_root_elecs    = unit_root_elecs;
    spk.unit_templates     = templates_full;
    spk.spatial_profiles   = spatial_full;
    spk.channel_positions  = chanpos_full;
    spk.n_wf               = N_WF;
    spk.n_chans            = N_CHANS_FULL;
    spk.fs                 = fs;
end
