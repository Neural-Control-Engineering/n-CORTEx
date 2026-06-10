function row = formatSpk_toDTS(spk, t_start_ms, t_stop_ms, bin_ms, sigma_ms)
% formatSpk_toDTS  Bin spike data for one trial into DTS-ready column structs.
%
% row = formatSpk_toDTS(spk, t_start_ms, t_stop_ms, bin_ms, sigma_ms)
%
% Inputs:
%   spk          — spk_struct from loadKS4_spk or loadRTSort_spk
%   t_start_ms   — trial start time in ms (relative to recording start)
%   t_stop_ms    — trial stop  time in ms
%   bin_ms       — bin width in ms (default 5)
%   sigma_ms     — Gaussian smoothing sigma in ms for spk_rates (default 25)
%
% Outputs (struct row):
%   .spk_raster          (n_units x n_tbins uint8) — spike count per bin
%   .spk_rates           (n_units x n_tbins single) — Gaussian-smoothed firing rate (Hz)
%   .spk_amplitudes      (n_units x n_tbins single) — max amplitude per bin (0 if no spike)
%   .spk_spatial_profiles(n_units x n_chans single) — static, normalised
%   .spk_templates       (n_wf x n_units single)    — root-channel waveform per unit
%   .spk_probe           (n_tbins x n_chans single) — collapsed probe (spk_amp * spat_prof)
%   .t_bins              (1 x n_tbins double) — bin centres in ms relative to t_start_ms

    if nargin < 4 || isempty(bin_ms),   bin_ms   = 5;  end
    if nargin < 5 || isempty(sigma_ms), sigma_ms = 25; end

    N_UNITS = numel(spk.unit_ids);
    N_CHANS = spk.n_chans;
    N_WF    = spk.n_wf;

    % --- time bins (centres relative to trial start) ---
    bin_edges  = t_start_ms : bin_ms : t_stop_ms;
    if numel(bin_edges) < 2
        bin_edges = [t_start_ms, t_start_ms + bin_ms];
    end
    n_tbins    = numel(bin_edges) - 1;
    t_bins     = (bin_edges(1:n_tbins) + bin_ms/2) - t_start_ms;  % relative ms

    % --- slice spikes to trial window ---
    in_win = spk.spike_times_ms >= bin_edges(1) & spk.spike_times_ms < bin_edges(end);
    st_win   = spk.spike_times_ms(in_win);
    cl_win   = spk.spike_clusters(in_win);
    amp_win  = spk.spike_amplitudes(in_win);

    % --- bin: raster and max-amplitude-per-bin ---
    raster     = zeros(N_UNITS, n_tbins, 'uint8');
    spk_amps   = zeros(N_UNITS, n_tbins, 'single');

    if ~isempty(st_win)
        [~, ~, bin_idx] = histcounts(st_win, bin_edges);
        valid_bins = bin_idx > 0 & bin_idx <= n_tbins;

        for u = 1:N_UNITS
            mask_u = valid_bins & (cl_win == u);
            if ~any(mask_u), continue; end
            bIdx  = bin_idx(mask_u);
            aVals = amp_win(mask_u);
            raster(u, :)   = uint8(accumarray(bIdx(:), ones(sum(mask_u),1), [n_tbins,1], @sum, 0)');
            spk_amps(u, :) = single(accumarray(bIdx(:), aVals(:), [n_tbins,1], @max, 0)');
        end
    end

    % --- Gaussian-smoothed firing rates ---
    sigma_bins  = sigma_ms / bin_ms;
    kern_half   = ceil(3 * sigma_bins);
    kern_x      = -kern_half : kern_half;
    kern        = exp(-kern_x.^2 / (2 * sigma_bins^2));
    kern        = kern / sum(kern);

    spk_rates = zeros(N_UNITS, n_tbins, 'single');
    for u = 1:N_UNITS
        spk_rates(u,:) = single(conv(double(raster(u,:)), kern, 'same') / (bin_ms/1000));
    end

    % --- static fields: root-channel templates, spatial profiles ---
    spk_templates = zeros(N_WF, N_UNITS, 'single');
    for u = 1:N_UNITS
        spk_templates(:, u) = single(spk.unit_templates(u, :, spk.unit_root_elecs(u)));
    end

    % --- collapsed probe: (n_tbins x n_chans) = spk_amps' * spatial_profiles ---
    spk_probe = single(double(spk_amps)' * double(spk.spatial_profiles));  % n_tbins x n_chans

    % --- pack output ---
    row.spk_raster          = raster;
    row.spk_rates           = spk_rates;
    row.spk_amplitudes      = spk_amps;
    row.spk_spatial_profiles= spk.spatial_profiles;
    row.spk_templates       = spk_templates;
    row.spk_probe           = spk_probe;
    row.t_bins              = t_bins;
end
