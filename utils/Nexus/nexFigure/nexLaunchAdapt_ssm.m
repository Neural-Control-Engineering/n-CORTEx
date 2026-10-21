function obj = nexLaunchAdapt_ssm(ctg)
% Launch adapter: build mdlObj_ssm from the categorical hub. Auto-discovered
% by nexLaunch_registry (figType = "ssm"). The ctg rides the Parent slot;
% nexon and source dfID come off the hub (ctg.nexon, ctg.dfID_source).
%
% Fit (nexFit_ssm.m) runs a Linear Gaussian SSM via pytafix/dynamax;
% mdlObj.SYS.DF_A.df ends up holding the fitted dynamics matrix. DM format
% is "stack" (stat2dm_stack): one sequence (or batch of sequences) along
% domain.DN, reduced per-block via mdlObj.Reducer when pMap.(FTR).divsPerBin
% is configured for block structure (see initReducer).
    obj = mdlObj_ssm(ctg, [], ctg.dfID_source);
end
