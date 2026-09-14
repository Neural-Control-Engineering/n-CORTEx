function DM = stat2dm_regression(mdlObj)
% Build design matrix for continuous-target regression.
% X: trial-averaged features [nTrials × nFeatures] — one row per trial.
% Y: trial-level target [nTrials × 1].
%
% Averaging over the time axis (DN(1)) rather than stacking all samples keeps
% the regression at the trial level so the Lasso/Ridge gradient is not
% diluted across 5000+ within-trial samples, each with the same Y label.
    STAT = mdlObj.TRAIN.STAT;
    dn   = char(mdlObj.domain.DN(1));

    % Per-trial mean over the DN(1) (time) axis → [nTrials × nFeatures]
    ptr = STAT.ptr(1);
    d1dim = ptr.(dn).dim;
    DM.X = cell2mat(cellfun(@(df) mean(df, d1dim), STAT.df, 'UniformOutput', false));

    Y_trial = STAT.(char(mdlObj.dfID_target));
    if iscell(Y_trial), Y_trial = [Y_trial{:}]'; end
    DM.Y = double(Y_trial(:));
end
