function nexFit_dpca(mdlObj, args)
% Fit dPCA on condition-averaged SSM latent trajectories.
%
% Parameters (nComp=20, nBins=4, lambda=[]):
%   nComp   — total dPCA components to extract
%   nBins   — quantile bins for continuous condition variables
%   lambda  — regularization; [] triggers dpca_optimizeLambda
%
% DM is built by stat2dm_dpca and must contain:
%   .X_avg          (N_latents × S1 [× S2 ...] × T) condition-averaged
%   .X_single       (N_latents × S1 [× S2 ...] × T × max_trials) NaN-padded
%   .combinedParams cell of marginalization index sets
%   .margNames      cell of human-readable marginalization labels

    % CFG HEADER
    nComp  = args.nComp;    % default = 20
    nBins = args.nBins; % default = 5
    lambda = args.lambda;   % default = []
    if ~isnumeric(lambda)
        lambda = str2num(char(lambda)); %#ok<ST2NM>  % recover if cfg stored '[]' as char
    end

    DM = mdlObj.DM;
    if isempty(DM) || ~isfield(DM, 'X_avg')
        error('nexFit_dpca: DM not built — call getDesignMatrix first.');
    end

    if isempty(lambda)
        fprintf('[nexFit_dpca] optimizing lambda...\n');
        lambda = dpca_optimizeLambda(DM.X_avg, DM.X_single, DM.numOfTrials, ...
            'combinedParams', DM.combinedParams, 'simultaneous', true, 'display', 'no');
        fprintf('[nexFit_dpca] optimal lambda = %.4g\n', lambda);
    end

    [W, V, whichMarg] = dpca(DM.X_avg, nComp, ...
        'combinedParams', DM.combinedParams, 'lambda', lambda);

    explVar = dpca_explainedVariance(DM.X_avg, W, V, ...
        'combinedParams', DM.combinedParams);

    mdlObj.W = struct( ...
        'W',         W, ...           % (N_latents × nComp) decoder — used in transform
        'V',         V, ...           % (N_latents × nComp) encoder
        'whichMarg', whichMarg, ...   % (1 × nComp) marginalization index per component
        'explVar',   explVar, ...
        'margNames', {DM.margNames}, ...
        'lambda',    lambda);

    fprintf('[nexFit_dpca] done: %d components across %d marginalizations\n', ...
        nComp, numel(DM.combinedParams));
end
