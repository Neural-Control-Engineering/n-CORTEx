function nexAnalysis_ephysAtlas(subjectDir, sessionLabel, phase, DF_features)
% Bayesian posterior update for one session's observed unit features.
%
% Aggregates per-unit features to per-channel (mean across units sharing root channel),
% computes log P(features | region) from /reference/ Gaussians, multiplies into the
% current phase posterior, normalises, and writes back to /posteriors/<phase>/.
% Only channels that have at least one unit are updated; all others inherit unchanged.
%
%   subjectDir    subject root directory (contains npxls/ephys_atlas.h5)
%   sessionLabel  DTS sessionLabel string — used to stamp /sessions/<sessionLabel>/contributed
%   phase         phase tag string ('spontaneous', 'Baseline', ...)
%   DF_features   output of nexOp_unitFeatures:
%                   df (n_units × n_features), ax.chans (root channel per unit),
%                   ax.measure (feature name string array)

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');
    if ~isfile(atlasFile)
        fprintf('[nexAnalysis_ephysAtlas] atlas file not found: %s\n', atlasFile);
        return;
    end

    % ── Load atlas structure ──────────────────────────────────────────────────
    region_acronyms = string(h5read(atlasFile, '/prior/region_acronyms'));
    channel_indices = double(h5read(atlasFile, '/prior/channel_indices'));
    n_reg = numel(region_acronyms);
    n_ch  = numel(channel_indices);

    phasePath = ['/posteriors/' char(phase)];
    try
        posterior = h5read(atlasFile, [phasePath '/posterior']);   % (n_ch × n_reg)
    catch
        % Phase has no posterior yet — bootstrap from prior
        posterior = h5read(atlasFile, '/prior/P');
        fprintf('[nexAnalysis_ephysAtlas] %s: no existing posterior, bootstrapping from prior\n', phase);
    end

    % ── Load reference Gaussians ──────────────────────────────────────────────
    % ref_mu, ref_sigma: (n_reg × n_ref_features), aligned to region_acronyms order
    ref_feature_names = string.empty(1, 0);
    ref_mu    = [];
    ref_sigma = [];

    for ri = 1:n_reg
        rname = char(region_acronyms(ri));
        refBase = ['/reference/' rname];
        try
            fnames = string(h5read(atlasFile, [refBase '/feature_names']));
            mu_r   = double(h5read(atlasFile, [refBase '/mu']));
            sig_r  = double(h5read(atlasFile, [refBase '/sigma']));
            if isempty(ref_feature_names)
                ref_feature_names = fnames(:)';
                ref_mu    = NaN(n_reg, numel(fnames));
                ref_sigma = NaN(n_reg, numel(fnames));
            end
            ref_mu(ri, :)    = mu_r(:)';
            ref_sigma(ri, :) = sig_r(:)';
        catch
        end
    end

    if isempty(ref_feature_names)
        fprintf('[nexAnalysis_ephysAtlas] no /reference/ data found — posterior unchanged\n');
        return;
    end

    % ── Feature intersection: observation ∩ reference ────────────────────────
    obs_names = DF_features.ax.measure;   % string array (n_features,)
    [~, obs_idx, ref_idx] = intersect(obs_names, ref_feature_names, 'stable');
    if isempty(obs_idx)
        fprintf('[nexAnalysis_ephysAtlas] no overlapping features between observation and reference — posterior unchanged\n');
        return;
    end
    fprintf('[nexAnalysis_ephysAtlas] %s / %s — using features: %s\n', ...
        sessionLabel, phase, strjoin(obs_names(obs_idx), ', '));

    % ── Aggregate per-unit → per-channel ─────────────────────────────────────
    unit_feat  = double(DF_features.df(:, obs_idx));   % (n_units × n_shared)
    root_chans = double(DF_features.ax.chans(:));       % (n_units,)

    [active_chans, ~, unit_to_ac] = unique(root_chans, 'stable');
    n_active = numel(active_chans);
    ch_feat  = NaN(n_active, numel(obs_idx));
    for ci = 1:n_active
        rows = unit_to_ac == ci;
        ch_feat(ci, :) = mean(unit_feat(rows, :), 1, 'omitnan');
    end

    % Map active channel numbers → posterior row indices
    [tf, ch_row] = ismember(active_chans, channel_indices);
    if ~any(tf)
        fprintf('[nexAnalysis_ephysAtlas] active channels not found in atlas channel_indices\n');
        return;
    end

    % ── Bayesian update ───────────────────────────────────────────────────────
    ref_mu_sub    = ref_mu(:, ref_idx);      % (n_reg × n_shared)
    ref_sigma_sub = ref_sigma(:, ref_idx);

    posterior_new = posterior;
    n_updated = 0;

    for ci = 1:n_active
        if ~tf(ci), continue; end
        row  = ch_row(ci);
        feat = ch_feat(ci, :);               % (1 × n_shared)

        % Log-likelihood: sum Gaussian log-pdf across features
        log_lik = zeros(n_reg, 1);
        for fi = 1:numel(obs_idx)
            if ~isfinite(feat(fi)), continue; end
            mu_f  = ref_mu_sub(:, fi);
            sig_f = ref_sigma_sub(:, fi);
            ok    = isfinite(mu_f) & sig_f > 0;
            log_lik(ok) = log_lik(ok) ...
                - 0.5 * ((feat(fi) - mu_f(ok)) ./ sig_f(ok)).^2 ...
                - log(sig_f(ok));
        end

        % Multiply log-likelihood into log-prior, normalise
        log_post = log(posterior(row, :)' + eps) + log_lik;
        log_post = log_post - max(log_post);
        p = exp(log_post);
        posterior_new(row, :) = (p / sum(p))';
        n_updated = n_updated + 1;
    end

    % ── Write updated phase posterior ─────────────────────────────────────────
    nexAtlas_h5overwrite(atlasFile, [phasePath '/posterior'], posterior_new);

    try
        n_sess = double(h5read(atlasFile, [phasePath '/n_sessions']));
    catch
        n_sess = 0;
    end
    nexAtlas_h5overwrite(atlasFile, [phasePath '/n_sessions'], double(n_sess + 1));
    nexAtlas_h5overwrite(atlasFile, [phasePath '/last_updated'], ...
        {char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'))});

    % Mark session record as contributed
    try
        sessPath = ['/sessions/' char(sessionLabel)];
        nexAtlas_h5overwrite(atlasFile, [sessPath '/contributed'], uint8(1));
    catch
    end

    % Refresh canonical posterior
    nexAtlas_mergeCanonical(atlasFile);

    fprintf('[nexAnalysis_ephysAtlas] %s / %s — %d/%d channels updated  (phase n_sessions=%d)\n', ...
        sessionLabel, phase, n_updated, n_active, n_sess + 1);
end
