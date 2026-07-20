function row = formatSpk_toDTS(spk, t_start_s, t_stop_s, bin_s, sigma_s)
% formatSpk_toDTS  Bin spike data for one trial into DTS-ready column structs.
%
% row = formatSpk_toDTS(spk, t_start_s, t_stop_s, bin_s, sigma_s)
%
% Inputs:
%   spk          — spk_struct from loadKS4_spk or loadRTSort_spk
%   t_start_s    — trial start time in s (relative to recording start)
%   t_stop_s     — trial stop  time in s
%   bin_s        — bin width in s (default 0.005)
%   sigma_s      — Gaussian smoothing sigma in s for spk_rates (default 0.025)
%
% Outputs (struct — 5 DFs + their axis vectors):
%   .activity     (n_units x n_tbins x 3 single) — measure axis = [raster,rate,amp]
%   .spatial      (n_units x n_chans single)     — static, normalised footprint
%   .templates    (n_wf x n_units single)        — root-channel waveform per unit
%   .probe        (n_tbins x n_chans single)     — collapsed probe (spk_amp * spat_prof)
%   .units        (n_units x 3 double)           — [root_elec, loc_x, loc_y]
%   .ax_unit      (1 x n_units double)  — unit ids
%   .ax_t         (1 x n_tbins double)  — bin centres (s) relative to t_start_s
%   .ax_chans     (1 x n_chans double)  — channel index
%   .ax_wf        (1 x n_wf double)     — sample within waveform window
%   .ax_measure   (1 x 3 string)        — ["raster","rate","amp"]
%   .ax_factor    (1 x 3 string)        — ["root_elec","loc_x","loc_y"] (units cols)
%   .ax_unitChans (1 x n_units double)  — root channel per unit; the activity DF's
%                                         'chans' label (co-indexed with unit, so it
%                                         colors units by channel via the same chans
%                                         registry the LFP/probe DFs use)
%   .unit_quality (n_units x 1 cellstr) — per-unit quality label

    if nargin < 4 || isempty(bin_s),   bin_s   = 0.005; end
    if nargin < 5 || isempty(sigma_s), sigma_s = 0.025; end

    N_UNITS = numel(spk.unit_ids);
    N_CHANS = spk.n_chans;
    N_WF    = spk.n_wf;

    % --- time bins (centres relative to trial start) ---
    bin_edges  = t_start_s : bin_s : t_stop_s;
    if numel(bin_edges) < 2
        bin_edges = [t_start_s, t_start_s + bin_s];
    end
    n_tbins    = numel(bin_edges) - 1;
    t_bins     = (bin_edges(1:n_tbins) + bin_s/2) - t_start_s;  % relative s

    % --- slice spikes to trial window ---
    in_win = spk.spike_times_s >= bin_edges(1) & spk.spike_times_s < bin_edges(end);
    st_win   = spk.spike_times_s(in_win);
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
    sigma_bins  = sigma_s / bin_s;
    kern_half   = ceil(3 * sigma_bins);
    kern_x      = -kern_half : kern_half;
    kern        = exp(-kern_x.^2 / (2 * sigma_bins^2));
    kern        = kern / sum(kern);

    spk_rates = zeros(N_UNITS, n_tbins, 'single');
    for u = 1:N_UNITS
        spk_rates(u,:) = single(conv(double(raster(u,:)), kern, 'same') / bin_s);  % counts/bin -> Hz
    end

    % --- static fields: root-channel templates, spatial profiles ---
    spk_templates = zeros(N_WF, N_UNITS, 'single');
    for u = 1:N_UNITS
        spk_templates(:, u) = single(spk.unit_templates(u, :, spk.unit_root_elecs(u)));
    end

    % --- collapsed probe: (n_tbins x n_chans) = spk_amps' * spatial_profiles ---
    spk_probe = single(double(spk_amps)' * double(spk.spatial_profiles));  % n_tbins x n_chans

    % --- pack output: 4 DFs + axis vectors (numeric axes; measure is string) ---
    % raster (uint8), rates & amps (single) stack along a 'measure' axis; cast
    % raster to single so the stack stays single (mixed concat would truncate).
    row = struct();
    row.activity   = cat(3, single(raster), spk_rates, spk_amps);  % unit × t × measure
    row.spatial    = spk.spatial_profiles;                          % unit × chan
    row.templates  = spk_templates;                                 % wf × unit
    row.probe      = spk_probe;                                     % t × chan
    row.units      = [double(spk.unit_root_elecs(:)), double(spk.unit_locs)];  % unit × [root, loc_x, loc_y]

    row.ax_unit    = 1:N_UNITS;                  % unit ids
    row.ax_t       = t_bins;                     % s, relative to trial start
    row.ax_chans   = 1:N_CHANS;                  % channel index
    row.ax_wf      = 1:N_WF;                      % sample within waveform window
    row.ax_measure = ["raster","rate","amp"];    % string measure axis
    row.ax_factor  = ["root_elec","loc_x","loc_y"];  % string factor axis (units DF cols)
    row.ax_unitChans = double(spk.unit_root_elecs(:))';  % activity 'chans' axis: root channel per unit (co-indexed with unit)

    row.unit_quality = spk.unit_quality;         % N_UNITS × 1 cellstr
end
