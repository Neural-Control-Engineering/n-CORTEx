function obj = nexLaunchAdaptMdl_violin(mdlObj)
% Launch adapter: open a nexObj_violin wired to a live mdlObj (e.g.
% mdlObj_lme) -- reads each RESULTS row's T_long (raw trial-level long
% table), not its df/ax p-value grid (that's nexLaunchAdaptMdl_monoGram's
% job on the SAME RESULTS row). Auto-discovered by nexLaunch_registryMdl
% (figType = "violin").
    obj = nexObj_violin(mdlObj);
end
