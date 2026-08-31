function [DF_templates, DF_spatial, DF_isi] = nexAtlas_spkToDFs(spk)
% Convert a normalized spk_struct (from loadKS4_spk or loadRTSort_spk) into
% the three DFs expected by nexAtlas_registerSession.
%
%   DF_templates   df (n_wf × n_units)   root-channel waveform per unit
%   DF_spatial     df (n_units × n_chans) spatial amplitude profile
%   DF_isi         df (n_units × 3)       [firing_rate_hz, cv_isi, burst_index]
%
% ISI stats are computed directly from raw spike trains (no binning needed).
% Burst threshold: 10 ms (consistent with nexOp_ISIstats default).

    n_units = numel(spk.unit_ids);
    n_wf    = spk.n_wf;

    % ── DF_templates: root-channel waveform per unit ──────────────────────────
    wf_data = zeros(n_wf, n_units, 'single');
    for u = 1:n_units
        rc = spk.unit_root_elecs(u);
        wf_data(:, u) = spk.unit_templates(u, :, rc);
    end
    DF_templates.df       = double(wf_data);
    DF_templates.ax.wf    = (1:n_wf)';
    DF_templates.ax.unit  = spk.unit_ids(:);
    DF_templates.ax.chans = spk.unit_root_elecs(:);

    % ── DF_spatial: spatial amplitude profile per unit ────────────────────────
    DF_spatial.df       = double(spk.spatial_profiles);   % (n_units × n_chans)
    DF_spatial.ax.unit  = spk.unit_ids(:);
    DF_spatial.ax.chans = (1:spk.n_chans)';

    % ── DF_isi: ISI stats from raw spike trains ───────────────────────────────
    burst_thresh = 0.010;   % 10 ms
    t_total = max(spk.spike_times_s) - min(spk.spike_times_s);

    stats = NaN(n_units, 3);
    for u = 1:n_units
        t = sort(spk.spike_times_s(spk.spike_clusters == u));
        if isempty(t), continue; end
        stats(u, 1) = numel(t) / (t_total + eps);          % firing_rate_hz
        if numel(t) >= 3
            isis = diff(t);
            stats(u, 2) = std(isis) / (mean(isis) + eps);  % cv_isi
            stats(u, 3) = mean(isis < burst_thresh);        % burst_index
        end
    end

    DF_isi.df         = stats;
    DF_isi.ax.unit    = spk.unit_ids(:);
    DF_isi.ax.chans   = spk.unit_root_elecs(:);
    DF_isi.ax.measure = ["firing_rate", "cv_isi", "burst_index"];
end
