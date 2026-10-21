function model = model_lme(~)
% Trivial no-op "model" initializer for mdlObj_lme, called by mdlObject's
% base constructor via the model_<modelID> convention. fitlme has no
% reusable estimator object (no scikit-style X/Y fit, no python model) --
% mdlObj_lme never reads mdlObj.model. Chain fitting lives in
% nexFit_lme.m/mdlObj_lme.computeSignificance instead.
    model = [];
end
