function obj = nexLaunchAdapt_pca(ctg)
% Launch adapter: build mdlObj_pca from the categorical hub. Auto-discovered
% by nexLaunch_registry (figType = "pca"). The ctg rides the Parent slot;
% nexon and source dfID come off the hub (ctg.nexon, ctg.dfID_source).
%
% Flow: Fit -> Transform writes the projected dfID (pca_<source>) into the
% DTS; the pca figure's "-> StateSpace" button then launches
% nexObj_stateSpace on that output, scoped by the same ctg.
    obj = mdlObj_pca(ctg, [], ctg.dfID_source);
end
