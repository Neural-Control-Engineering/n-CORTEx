function DF_out = nexOp_unitFeatures(DF_templates, args)
% Compute per-unit waveform features and cell-type labels from a templates DF.
%
% Input DF (spk_templates):
%   df       (n_wf × n_units)    root-channel waveform per unit
%   ax.wf    (n_wf,)             sample indices (1:N_WF)
%   ax.unit  (n_units,)          local unit IDs
%   ax.chans (n_units,)          root channel per unit
%
% Optional args fields:
%   fs            sampling rate Hz (default 30000)
%   DF_spatial    spk_spatial DF (df: n_units × n_chans) — enables spatial features
%   DF_isi        output of nexOp_ISIstats — appends firing stats to feature matrix
%
% Output DF:
%   df        (n_units × n_features)   feature matrix
%   ax.unit   (n_units,)
%   ax.chans  (n_units,)               root channel per unit
%   ax.measure string array            feature names (same order as df columns)
%   labels.cell_type  (n_units,) string — "RSU" / "FSU" / "unclassified"
%   labels.burst_mode (n_units,) logical — thalamic burst flag (from DF_isi if present)
%
% Feature descriptions:
%   ptd_ms          peak-to-trough duration — primary FSU/RSU discriminator
%   half_width_ms   spike width at 50% of trough depth
%   repol_slope     repolarization rate (trough→peak), normalised amplitude/sample
%   pt_ratio        |peak| / |trough| — waveform asymmetry
%   footprint_nch   channels with amplitude > 50% of max (spatial extent proxy)
%   peak_amp        max amplitude across channels (from DF_spatial if supplied)
%   firing_rate_hz  (from DF_isi if supplied)
%   cv_isi          (from DF_isi if supplied)
%   burst_index     (from DF_isi if supplied)

    if nargin < 2 || isempty(args), args = struct(); end
    fs          = getf(args, 'fs',         30000);
    DF_spatial  = getf(args, 'DF_spatial', []);
    DF_isi      = getf(args, 'DF_isi',     []);

    waveforms = double(DF_templates.df);     % (n_wf × n_units)
    n_units   = size(waveforms, 2);

    % ── Waveform features (one pass per unit) ────────────────────────────────
    ptd_ms       = NaN(n_units, 1);
    half_width_ms = NaN(n_units, 1);
    repol_slope  = NaN(n_units, 1);
    pt_ratio     = NaN(n_units, 1);

    for u = 1:n_units
        wf = waveforms(:, u);
        try
            [ptd_ms(u), half_width_ms(u), repol_slope(u), pt_ratio(u)] = ...
                waveformMetrics(wf, fs);
        catch
        end
    end

    % ── Spatial features (optional) ───────────────────────────────────────────
    footprint_nch = NaN(n_units, 1);
    peak_amp      = NaN(n_units, 1);
    if ~isempty(DF_spatial) && isfield(DF_spatial, 'df')
        sp = double(DF_spatial.df);           % (n_units × n_chans)
        for u = 1:size(sp, 1)
            row      = sp(u, :);
            mx       = max(row);
            peak_amp(u)      = mx;
            footprint_nch(u) = sum(row >= 0.5 * mx);
        end
    end

    % ── Assemble feature matrix ───────────────────────────────────────────────
    feat_data    = [ptd_ms, half_width_ms, repol_slope, pt_ratio, ...
                    footprint_nch, peak_amp];
    feat_names   = ["ptd_ms","half_width_ms","repol_slope","pt_ratio", ...
                    "footprint_nch","peak_amp_au"];

    % ── ISI stats (optional, appended) ───────────────────────────────────────
    if ~isempty(DF_isi) && isfield(DF_isi, 'df')
        % Match units between DF_isi and DF_templates (may differ if pooled)
        isi_data = NaN(n_units, 3);
        [tf, loc] = ismember(double(DF_templates.ax.unit), double(DF_isi.ax.unit));
        isi_data(tf, :) = double(DF_isi.df(loc(tf), :));  % fr, cv, burst
        feat_data  = [feat_data,  isi_data];
        feat_names = [feat_names, DF_isi.ax.measure];
    end

    % ── Cell-type labels ─────────────────────────────────────────────────────
    cell_type = repmat("unclassified", n_units, 1);
    cell_type(ptd_ms <  0.40) = "FSU";
    cell_type(ptd_ms >= 0.50) = "RSU";

    % Thalamic burst mode: detectable only when ISI data is available
    burst_mode = false(n_units, 1);
    if ~isempty(DF_isi) && isfield(DF_isi, 'df')
        % Burst index > 0.15 + CV-ISI > 1 → strong burst-mode indicator
        bi_col  = find(DF_isi.ax.measure == "burst_index", 1);
        cv_col  = find(DF_isi.ax.measure == "cv_isi",      1);
        if ~isempty(bi_col) && ~isempty(cv_col)
            bi = feat_data(:, 4 + bi_col);   % offset: 6 waveform cols come first
            cv = feat_data(:, 4 + cv_col);
            burst_mode = bi > 0.15 & cv > 1.0;
        end
    end

    % ── Pack output ──────────────────────────────────────────────────────────
    DF_out.df            = feat_data;
    DF_out.ax.unit       = DF_templates.ax.unit;
    DF_out.ax.chans      = DF_templates.ax.chans;
    DF_out.ax.measure    = feat_names;
    DF_out.labels.cell_type  = cell_type;
    DF_out.labels.burst_mode = burst_mode;
end

% ── Waveform metrics for a single 1-D waveform ───────────────────────────────

function [ptd_ms, half_width_ms, repol_slope, pt_ratio] = waveformMetrics(wf, fs)
% All time values in ms; amplitudes in native (arbitrary) units.
% Convention: trough = most negative deflection (extracellular AP).
% If waveform is inverted (positive peak dominant), metrics still computed
% correctly because trough is identified as the minimum regardless.

    ms_per_sample = 1000 / fs;

    % Trough: most negative sample
    [trough_amp, t_idx] = min(wf);

    % Peak: maximum after the trough (repolarization overshoot)
    post_trough  = wf(t_idx:end);
    [peak_amp, p_rel] = max(post_trough);
    p_idx        = t_idx + p_rel - 1;

    ptd_ms   = (p_idx - t_idx) * ms_per_sample;
    pt_ratio = abs(peak_amp) / (abs(trough_amp) + eps);

    % Half-width: width of trough at 50% trough depth (below zero baseline)
    half_amp = trough_amp / 2;                    % negative value
    % Left crossing (before trough)
    left_seg  = wf(1:t_idx);
    left_idx  = find(left_seg >= half_amp, 1, 'last');
    % Right crossing (after trough, before peak)
    right_seg = wf(t_idx:end);
    right_rel = find(right_seg >= half_amp, 1, 'first');
    right_idx = t_idx + right_rel - 2;

    if ~isempty(left_idx) && ~isempty(right_rel)
        half_width_ms = (right_idx - left_idx) * ms_per_sample;
    else
        half_width_ms = NaN;
    end

    % Repolarization slope: linear fit from trough to peak, normalised by trough depth
    if p_idx > t_idx
        seg      = wf(t_idx:p_idx);
        x        = (0:numel(seg)-1)';
        coeffs   = polyfit(x, seg, 1);
        repol_slope = coeffs(1) / (abs(trough_amp) + eps);  % normalised slope per sample
    else
        repol_slope = NaN;
    end
end

function v = getf(s, field, default)
    if isfield(s, field), v = s.(field); else, v = default; end
end
