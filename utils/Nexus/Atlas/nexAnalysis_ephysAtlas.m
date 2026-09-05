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

    % ── Feature weights ───────────────────────────────────────────────────────
    % Per-feature likelihood weights in [0,1]. Stored in /config/feature_weights/
    % so they can be tuned per-subject without touching code.
    % Default: 1.0 for all features. Condition-sensitive features (e.g. firing_rate)
    % should be downweighted when the reference is poorly matched to recording conditions.
    feat_weights = ones(1, numel(obs_idx));
    try
        cfg_names   = string(h5read(atlasFile, '/config/feature_weights/names'));
        cfg_weights = h5read(atlasFile, '/config/feature_weights/weights');
        for fi = 1:numel(obs_idx)
            hit = find(cfg_names == obs_names(obs_idx(fi)), 1);
            if ~isempty(hit)
                feat_weights(fi) = cfg_weights(hit);
            end
        end
    catch
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

        % Log-likelihood: weighted sum of Gaussian log-pdf across features.
        % n_contrib tracks how many features contributed per region so that
        % regions with fewer defined reference entries are not structurally
        % disadvantaged against regions with full coverage.
        log_lik   = zeros(n_reg, 1);
        n_contrib = zeros(n_reg, 1);
        for fi = 1:numel(obs_idx)
            if ~isfinite(feat(fi)) || feat_weights(fi) == 0, continue; end
            mu_f  = ref_mu_sub(:, fi);
            sig_f = ref_sigma_sub(:, fi);
            ok    = isfinite(mu_f) & sig_f > 0;
            log_lik(ok)   = log_lik(ok) + feat_weights(fi) * ...
                (- 0.5 * ((feat(fi) - mu_f(ok)) ./ sig_f(ok)).^2 ...
                 - log(sig_f(ok)));
            n_contrib(ok) = n_contrib(ok) + feat_weights(fi);
        end

        % Normalise log-likelihood per region by total contributing weight so
        % all regions are compared on a per-feature basis regardless of how
        % many NaN entries their reference has.
        norm_w   = max(n_contrib, 1e-6);
        log_lik  = log_lik ./ norm_w;

        % Multiply log-likelihood into log-prior, normalise
        log_post = log(posterior(row, :)' + eps) + log_lik;
        log_post = log_post - max(log_post);
        p = exp(log_post);
        posterior_new(row, :) = (p / sum(p))';
        n_updated = n_updated + 1;
    end

    % ── Per-phase raw feature distributions by MAP region ────────────────────
    % Each active channel is assigned to its MAP region (argmax of the updated
    % posterior).  Raw mean ± std of ch_feat for those channels is accumulated
    % across sessions so the panel can show an unobscured empirical comparison
    % against the IBL reference — no posterior weighting that would echo the
    % prior back into the measurement.
    CANONICAL    = ["ptd_ms","firing_rate","cv_isi"];
    n_canon      = numel(CANONICAL);
    active_valid = find(tf);
    if ~isempty(active_valid)
        p_valid    = posterior_new(ch_row(active_valid), :);  % (n_valid × n_reg)
        [~, map_ri] = max(p_valid, [], 2);                    % MAP region per channel

        for ri = 1:n_reg
            assigned = active_valid(map_ri == ri);
            if isempty(assigned), continue; end

            feat_mat = ch_feat(assigned, :);   % (n_assigned × n_shared)
            n_ch_r   = size(feat_mat, 1);
            mu_sess  = NaN(1, n_canon);
            sd_sess  = NaN(1, n_canon);
            for ci = 1:n_canon
                hit = find(obs_names(obs_idx) == CANONICAL(ci), 1);
                if ~isempty(hit)
                    vals = feat_mat(isfinite(feat_mat(:, hit)), hit);
                    if numel(vals) >= 1, mu_sess(ci) = mean(vals); end
                    if numel(vals) >= 2, sd_sess(ci) = std(vals);  end
                end
            end
            if all(~isfinite(mu_sess)), continue; end

            rfPath = [phasePath '/region_features/' char(region_acronyms(ri))];
            try
                mu_prev = double(h5read(atlasFile, [rfPath '/mu']));
                sd_prev = double(h5read(atlasFile, [rfPath '/sigma']));
                n_prev  = double(h5read(atlasFile, [rfPath '/n']));
            catch
                mu_prev = NaN(1, n_canon);  sd_prev = NaN(1, n_canon);  n_prev = 0;
            end

            mu_new = mu_prev;  sd_new = sd_prev;
            for ci = 1:n_canon
                if isfinite(mu_sess(ci))
                    if isfinite(mu_prev(ci)) && n_prev > 0
                        n_tot       = n_prev + n_ch_r;
                        mu_new(ci)  = (n_prev*mu_prev(ci) + n_ch_r*mu_sess(ci)) / n_tot;
                        % Combine variances: Var_combined = (n1*Var1 + n2*Var2) / (n1+n2)
                        v1 = double(isfinite(sd_prev(ci))) * sd_prev(ci)^2;
                        v2 = double(isfinite(sd_sess(ci))) * sd_sess(ci)^2;
                        sd_new(ci)  = sqrt((n_prev*v1 + n_ch_r*v2) / n_tot);
                    else
                        mu_new(ci)  = mu_sess(ci);
                        sd_new(ci)  = sd_sess(ci);
                    end
                end
            end
            nexAtlas_h5overwrite(atlasFile, [rfPath '/mu'],           mu_new);
            nexAtlas_h5overwrite(atlasFile, [rfPath '/sigma'],        sd_new);
            nexAtlas_h5overwrite(atlasFile, [rfPath '/n'],            double(n_prev + n_ch_r));
            nexAtlas_h5overwrite(atlasFile, [rfPath '/feature_names'],cellstr(CANONICAL));
        end
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
