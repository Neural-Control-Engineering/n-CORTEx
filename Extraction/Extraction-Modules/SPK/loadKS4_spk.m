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
%   unit_root_elecs     (N_UNITS x 1)  — root channel index, 1-indexed
%   unit_templates      (N_UNITS x N_WF x N_CHANS single) — mean waveforms
%   spatial_profiles    (N_UNITS x N_CHANS) — normalised peak-to-peak amplitude
%   channel_positions   (N_CHANS x 2)  — x/y in um
%   n_wf                scalar — waveform window in samples
%   n_chans             scalar
%   fs                  scalar — sample rate (Hz)

    fs = 30000;  % Neuropixels AP band default; overridden from ops if present

    % --- load KS4 files ---
    spike_inds    = double(readNPY(fullfile(ks4_dir, 'spike_times.npy')));     % samples
    spike_clust   = double(readNPY(fullfile(ks4_dir, 'spike_clusters.npy')));  % 0-indexed
    amplitudes_ks = double(readNPY(fullfile(ks4_dir, 'amplitudes.npy')));
    templates_all = readNPY(fullfile(ks4_dir, 'templates.npy'));               % (n_tmpl x N_WF x N_CHANS)
    chan_pos      = readNPY(fullfile(ks4_dir, 'channel_positions.npy'));        % (N_CHANS x 2)

    cluster_group  = readtable(fullfile(ks4_dir, 'cluster_group.tsv'),  ...
        'FileType','text','Delimiter','\t');
    cluster_amp    = readtable(fullfile(ks4_dir, 'cluster_Amplitude.tsv'), ...
        'FileType','text','Delimiter','\t');

    % --- build unit list from cluster_group (good + mua + noise) ---
    cluster_ids = sort(unique(spike_clust));  % 0-indexed KS4 IDs
    N_UNITS     = numel(cluster_ids);
    N_WF        = size(templates_all, 2);
    N_CHANS     = size(templates_all, 3);

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
        unit_root_elecs(u)     = root_ch;         % 1-indexed
        unit_locs(u,:)         = chan_pos(root_ch,:);
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

    % --- assemble output ---
    spk.spike_times_s      = spike_inds / fs;         % samples -> seconds
    spk.spike_clusters     = spike_clusters_remapped;
    spk.spike_amplitudes   = amplitudes_ks(:);
    spk.unit_ids           = (1:N_UNITS)';
    spk.unit_quality       = unit_quality;
    spk.unit_locs          = unit_locs;
    spk.unit_root_elecs    = unit_root_elecs;
    spk.unit_templates     = unit_templates;
    spk.spatial_profiles   = spatial_profiles;
    spk.channel_positions  = chan_pos;
    spk.n_wf               = N_WF;
    spk.n_chans            = N_CHANS;
    spk.fs                 = fs;
end
