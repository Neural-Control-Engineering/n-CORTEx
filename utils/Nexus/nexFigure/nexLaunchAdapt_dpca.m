function obj = nexLaunchAdapt_dpca(ctg)
% Launch adapter: build mdlObj_dPCA from the categorical hub. Auto-discovered
% by nexLaunch_registry (figType = "dpca"). The ctg rides the Parent slot;
% nexon and source dfID come off the hub (ctg.nexon, ctg.dfID_source).
%
% dPCA demixes condition-independent (time) and condition-dependent variance
% across latent trajectories. Typical source: ssm_<dfID> or pca_<dfID>.
% Select condition variables in the Condition Variables panel before Fit.
    obj = mdlObj_dPCA(ctg, [], ctg.dfID_source);
end
