function nexFit_lds(mdlObj, args)
% LDS (Linear Dynamical System) coefficient features for trial-level regression.
%
% Fits a per-trial AR(1) model in a low-dimensional PCA subspace and uses the
% eigenvalues of the fitted transition matrix as features. The PCA basis is
% estimated once from all training trajectories and fixed for test trials.
%
% Feature vector per trial: [real(eigs), imag(eigs)] of the nLatent dominant
% eigenvalues of A, where A satisfies z(t+1) ≈ A z(t) in PCA space.
%   real(eig) → decay / growth rate along that mode
%   imag(eig) → oscillation frequency of that mode
%
% Requires at least nLatent+1 time points per trial for a stable A estimate.
%
% W.pcaBasis     — [nChans × nLatent] PCA projection matrix
% W.trainMean    — [1 × nChans] mean subtracted before projection
% W.buildTestX   — feature extraction closure (captures pcaBasis, trainMean)
% W.isTrialLevel — true

    % CFG HEADER
    nLatent = args.nLatent; % default = 3

    STAT_train = mdlObj.TRAIN.STAT;
    tVar       = char(mdlObj.dfID_target);
    d1         = mdlObj.domain.D1;

    % ── 1. Global PCA basis from stacked training trajectories ───────────────
    X_stack  = mdlObj.DM.X;                            % [nSamples × nChans]
    mu       = mean(X_stack, 1);                       % [1 × nChans]
    [~, ~, V] = svd(X_stack - mu, 'econ');             % V: [nChans × min(nSamples,nChans)]
    nLatent  = min(nLatent, size(V, 2));
    V        = V(:, 1:nLatent);                        % [nChans × nLatent]

    % ── 2. Per-trial AR(1) eigenvalue features ───────────────────────────────
    featFcn = @(ST) ldsFeatures(ST, d1, V, mu);

    mdlObj.DM.X = featFcn(STAT_train);                 % [nTrials × 2*nLatent]

    Y_trial = STAT_train.(tVar);
    if iscell(Y_trial), Y_trial = [Y_trial{:}]'; end
    mdlObj.DM.Y = double(Y_trial(:));

    % ── 3. Store for test scoring ────────────────────────────────────────────
    mdlObj.W = struct( ...
        'pcaBasis',     V, ...
        'trainMean',    mu, ...
        'buildTestX',   @(ST) ldsFeatures(ST, d1, V, mu), ...
        'isTrialLevel', true);

    fprintf('[nexFit_lds] PCA %d dims → AR(1) eigvals × 2 = %d features  [%d trials]\n', ...
        nLatent, 2*nLatent, height(STAT_train));
    nexFit_linear(mdlObj, args);
end


% ── AR(1) eigenvalue extraction ───────────────────────────────────────────────

function X = ldsFeatures(STAT, d1, V, mu)
    nTrials  = height(STAT);
    nLatent  = size(V, 2);
    X        = zeros(nTrials, 2*nLatent);
    for i = 1:nTrials
        traj = trialTrajectory(STAT.df{i}, STAT.ptr(i), d1);   % [nTime × nChans]
        if isempty(traj) || size(traj,1) < nLatent+2, continue; end
        z  = (traj - mu) * V;                                   % [nTime × nLatent]
        ev = arEigenvalues(z, nLatent);
        X(i, 1:nLatent)       = real(ev);
        X(i, nLatent+1:end)   = imag(ev);
    end
end

function ev = arEigenvalues(z, nLatent)
% Fit AR(1): z(t+1) = A z(t) via OLS, return dominant eigenvalues.
    Z1 = z(1:end-1,:);
    Z2 = z(2:end,:);
    A  = (Z1 \ Z2)';                             % [nLatent × nLatent]
    ev = eig(A);
    [~, ord] = sort(abs(ev), 'descend');
    ev = ev(ord(1:nLatent));
end

function traj = trialTrajectory(df, ptr, d1)
% Return [nTime × nChans] with time in the first dimension.
    if isempty(df), traj = []; return; end
    tDim   = ptr.(char(d1)).dim;
    nDims  = ndims(df);
    pOrder = [tDim, setdiff(1:nDims, tDim)];
    traj   = reshape(permute(df, pOrder), size(df, tDim), []);
end
