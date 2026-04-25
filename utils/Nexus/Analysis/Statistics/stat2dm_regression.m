function DM = stat2dm_regression(mdlObj)
% Build design matrix for continuous-target regression.
% X: all trial time points stacked (T_total × features).
% Y: trial-level target replicated once per time point so sizes match.
    STAT = mdlObj.TRAIN.STAT;
    DM.X = nexOp_stackSamples(STAT, "stack", mdlObj.domain.D1);
    % Trial-level Y — replicate each value across its trial's T_i time points
    Y_trial = STAT.(char(mdlObj.dfID_target));
    if iscell(Y_trial), Y_trial = [Y_trial{:}]'; end
    nRows = cellfun(@(df) size(df,1), STAT.df);
    DM.Y  = double(repelem(double(Y_trial(:)), nRows));
end
