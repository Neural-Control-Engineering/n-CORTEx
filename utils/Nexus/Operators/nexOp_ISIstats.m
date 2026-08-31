function DF_out = nexOp_ISIstats(DF_in, args)
% Compute per-unit firing rate, CV-ISI, and burst index from a spike activity DF.
%
% Input DF (spk_activity):
%   df       (n_units × n_tbins × 3)  measure = [raster, rate, amp]
%   ax.unit  (n_units,)               local unit IDs
%   ax.t     (n_tbins,)               bin centres in seconds
%   ax.chans (n_units,)               root channel per unit (ax_unitChans)
%
% Output DF:
%   df       (n_units × 3)            [firing_rate_Hz, cv_isi, burst_index]
%   ax.unit  (n_units,)
%   ax.chans (n_units,)               root channel — for channel-level aggregation
%   ax.measure ["firing_rate","cv_isi","burst_index"]
%
% firing_rate  — mean of the smoothed rate slice (Hz), averaged over all time bins
% cv_isi       — std(ISI)/mean(ISI) from the raster; NaN when < 3 spikes
% burst_index  — fraction of ISIs below burst_thresh_s (default 10 ms)
%
% Limitation: ISI resolution is limited by bin width (~5 ms). Sufficient for
% atlas feature discrimination; use raw spike times for finer-grained analysis.

    if nargin < 2 || isempty(args), args = struct(); end
    burst_thresh_s = getfield_default(args, 'burst_thresh_s', 0.010);

    data    = double(DF_in.df);              % (n_units × n_tbins × 3)
    t       = double(DF_in.ax.t(:)');        % (1 × n_tbins)
    n_units = size(data, 1);

    raster  = squeeze(data(:, :, 1));        % (n_units × n_tbins)  binary counts
    rates   = squeeze(data(:, :, 2));        % (n_units × n_tbins)  smoothed Hz

    stats = NaN(n_units, 3);                 % [fr, cv, burst]

    for u = 1:n_units
        % Firing rate: mean of smoothed rate over session
        stats(u, 1) = mean(rates(u, :), 'omitnan');

        % ISI from raster: find bins with spikes, compute inter-spike intervals
        spike_bins  = find(raster(u, :) > 0);
        if numel(spike_bins) < 3
            % cv_isi and burst_index remain NaN
            continue;
        end
        spike_t = t(spike_bins);             % spike times (s) at bin centres
        isis    = diff(spike_t);             % ISI sequence (s)

        stats(u, 2) = std(isis) / mean(isis);           % CV-ISI
        stats(u, 3) = mean(isis < burst_thresh_s);      % burst index
    end

    DF_out.df         = stats;
    DF_out.ax.unit    = DF_in.ax.unit;
    DF_out.ax.chans   = DF_in.ax.chans;    % root channel per unit — preserved for aggregation
    DF_out.ax.measure = ["firing_rate", "cv_isi", "burst_index"];
end

function v = getfield_default(s, field, default)
    if isfield(s, field), v = s.(field); else, v = default; end
end
