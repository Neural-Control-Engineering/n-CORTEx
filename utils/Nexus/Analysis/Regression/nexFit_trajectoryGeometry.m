function nexFit_trajectoryGeometry(mdlObj, args)
% Trajectory geometry features for trial-level linear regression.
%
% Summarises each trial's neural trajectory as a vector of scalar geometric
% quantities — no training parameters are estimated, so the same extraction
% function applies identically to train and test trials.
%
% Available features (comma-separated string):
%   pathLen    — total Euclidean path length
%   endDisp    — start-to-end displacement (net movement)
%   speed_mean — mean step-to-step speed
%   speed_var  — variance of step-to-step speed (regularity)
%   curvature  — mean turning angle between consecutive steps (radians)
%
% DM is overridden to trial-level [nTrials × nFeatures] / Y [nTrials × 1].
%
% W.buildTestX  — feature extraction closure (no fitted params)
% W.isTrialLevel — true

    % CFG HEADER
    features = args.features; % default = "pathLen,endDisp,speed_var"

    d1       = mdlObj.domain.D1;
    featList = strtrim(strsplit(char(features), ','));
    featFcn  = @(ST) extractGeoFeatures(ST, d1, featList);

    STAT_train = mdlObj.TRAIN.STAT;
    tVar       = char(mdlObj.dfID_target);

    % ── Trial-level features and Y ───────────────────────────────────────────
    mdlObj.DM.X = featFcn(STAT_train);

    Y_trial = STAT_train.(tVar);
    if iscell(Y_trial), Y_trial = [Y_trial{:}]'; end
    mdlObj.DM.Y = double(Y_trial(:));

    % ── Store for test scoring ───────────────────────────────────────────────
    mdlObj.W = struct( ...
        'buildTestX',   featFcn, ...
        'isTrialLevel', true);

    fprintf('[nexFit_trajectoryGeometry] features: %s  [%d trials × %d features]\n', ...
        features, height(STAT_train), numel(featList));
    nexFit_linear(mdlObj, args);
end


% ── Feature extraction ────────────────────────────────────────────────────────

function X = extractGeoFeatures(STAT, d1, featList)
    nTrials = height(STAT);
    nFeat   = numel(featList);
    X       = zeros(nTrials, nFeat);
    for i = 1:nTrials
        traj = trialTrajectory(STAT.df{i}, STAT.ptr(i), d1);  % [nTime × nChans]
        if isempty(traj), continue; end
        for fi = 1:nFeat
            X(i, fi) = geoFeature(traj, featList{fi});
        end
    end
end

function v = geoFeature(traj, feat)
    steps = diff(traj, 1, 1);             % [nTime-1 × nChans]
    speed = sqrt(sum(steps.^2, 2));       % [nTime-1 × 1]
    switch feat
        case 'pathLen'
            v = sum(speed);
        case 'endDisp'
            v = norm(traj(end,:) - traj(1,:));
        case 'speed_mean'
            v = mean(speed);
        case 'speed_var'
            v = var(speed);
        case 'curvature'
            nz    = speed > 0;
            dirs  = steps(nz,:) ./ speed(nz);
            if size(dirs,1) < 2
                v = 0;
            else
                dots = sum(dirs(1:end-1,:) .* dirs(2:end,:), 2);
                v    = mean(acos(max(-1, min(1, dots))));
            end
        otherwise
            warning('[nexFit_trajectoryGeometry] unknown feature "%s"', feat);
            v = 0;
    end
end

function traj = trialTrajectory(df, ptr, d1)
% Return [nTime × nChans] with time in the first dimension.
    if isempty(df), traj = []; return; end
    tDim   = ptr.(char(d1)).dim;
    nDims  = ndims(df);
    pOrder = [tDim, setdiff(1:nDims, tDim)];
    traj   = reshape(permute(df, pOrder), size(df, tDim), []);
end
