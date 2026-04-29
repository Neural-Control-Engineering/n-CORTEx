function nexFit_tdr(mdlObj, args)
% Time-resolved TDR — estimate β(t) at every time bin, collect each trial's
% projected time course as its feature vector, then fit trial-level Ridge.
%
% Two-stage compression:
%   Stage 1 (spatial)  — β(t) collapses nChans → 1 scalar per time bin.
%                        β is estimated from condition-averaged (binned) data
%                        so within-trial noise is suppressed.
%   Stage 2 (temporal) — Ridge regression on the [nTrials × T] DM learns
%                        which time bins of the projection predict Y.
%
% DM shape after this function: [nTrials × T_common] / Y [nTrials × 1].
% T_common = min(nRows) across training trials unless args.T_common overrides.
%
% Variable-length trials: β(t) at bin t uses all trials that reach t.
% Projection truncates at T_common for all trials.
%
% W.beta_mat    — [T_common × nChans] time-resolved regression axes
% W.T_common    — time dimension used for the DM
% W.buildTestX  — @(STAT_test) → [nTestTrials × T_common]
% W.isTrialLevel — true

    % CFG HEADER
    nBins    = args.nBins;    % default = 5
    T_common = args.T_common; % default = 0  (0 = use min trial length)

    STAT_train = mdlObj.TRAIN.STAT;
    tVar       = char(mdlObj.dfID_target);
    nTrials    = height(STAT_train);

    % Stack samples — TDR always needs the full [T_total × nChans] form for
    % time-resolved β estimation, regardless of what stat2dm_* produced.
    X_stack = nexOp_stackSamples(STAT_train, "stack", mdlObj.domain.D1);
    nChans  = size(X_stack, 2);

    % ── Trial layout in stacked matrix ───────────────────────────────────────
    nRows  = cellfun(@(df) size(df,1), STAT_train.df);
    ends   = cumsum(nRows);
    starts = ends - nRows + 1;
    maxT   = max(nRows);

    if T_common <= 0
        T_common = min(nRows);
    end
    T_common = min(T_common, maxT);

    % ── Bin Y (fixed partition used at every time bin) ───────────────────────
    Y_train = STAT_train.(tVar);
    if iscell(Y_train), Y_train = [Y_train{:}]'; end
    Y_train = double(Y_train(:));

    edges      = quantile(Y_train, linspace(0, 1, nBins+1));
    edges(end) = edges(end) + abs(edges(end))*eps + eps;
    [~, binIdx] = histc(Y_train, edges); %#ok<HISTC>
    binIdx = min(binIdx, nBins);
    Y_bin  = accumarray(binIdx, Y_train, [nBins,1], @mean);

    % ── Stage 1: time-resolved β estimation ─────────────────────────────────
    beta_mat = zeros(T_common, nChans);
    for t = 1:T_common
        hasBin  = nRows >= t;
        if sum(hasBin) < 2*nBins, continue; end

        rowIdx   = starts(hasBin) + t - 1;
        X_t      = X_stack(rowIdx, :);            % [nActive × nChans]
        binIdx_t = binIdx(hasBin);

        X_bin_t = zeros(nBins, nChans);
        for b = 1:nBins
            mask = binIdx_t == b;
            if any(mask), X_bin_t(b,:) = mean(X_t(mask,:), 1); end
        end

        valid = vecnorm(X_bin_t, 2, 2) > eps;
        if sum(valid) < 2, continue; end
        b_t = X_bin_t(valid,:) \ Y_bin(valid);
        n   = norm(b_t);
        if n < eps, continue; end
        beta_mat(t,:) = b_t / n;
    end

    % ── Stage 2: collect per-trial projected time courses → [nTrials × T] ───
    mdlObj.DM.X = buildTDRMatrix(X_stack, starts, nRows, beta_mat, T_common);

    Y_trial = STAT_train.(tVar);
    if iscell(Y_trial), Y_trial = [Y_trial{:}]'; end
    mdlObj.DM.Y = double(Y_trial(:));   % trial-level Y, no replication

    % ── Store for test scoring ───────────────────────────────────────────────
    d1 = mdlObj.domain.D1;
    mdlObj.W = struct( ...
        'beta_mat',     beta_mat, ...
        'T_common',     T_common, ...
        'buildTestX',   @(ST) buildTDRMatrix( ...
                            nexOp_stackSamples(ST, "stack", d1), ...
                            cumsum(cellfun(@(df) size(df,1), ST.df)) - cellfun(@(df) size(df,1), ST.df) + 1, ...
                            cellfun(@(df) size(df,1), ST.df), ...
                            beta_mat, T_common), ...
        'isTrialLevel', true);

    nEstimated = sum(vecnorm(beta_mat, 2, 2) > eps);
    fprintf('[nexFit_tdr] β(t): %d/%d bins estimated  DM: [%d trials × %d time]\n', ...
        nEstimated, T_common, nTrials, T_common);
    nexFit_linear(mdlObj, args);
end


% ── Build [nTrials × T_common] TDR feature matrix ────────────────────────────
function X_tdr = buildTDRMatrix(X_stack, starts, nRows, beta_mat, T_common)
% For each trial, dot each time sample with its time-specific β(t),
% returning one projected time course per trial as a row.
    nTrials = numel(nRows);
    X_tdr   = zeros(nTrials, T_common);
    for i = 1:nTrials
        T_i  = min(nRows(i), T_common);
        if T_i < 1, continue; end
        rows = starts(i) : starts(i) + T_i - 1;
        % [T_i × nChans] .* [T_i × nChans] → sum across chans → [T_i × 1]
        X_tdr(i, 1:T_i) = sum(X_stack(rows,:) .* beta_mat(1:T_i,:), 2)';
    end
end
