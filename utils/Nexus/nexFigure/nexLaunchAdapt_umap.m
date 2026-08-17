function obj = nexLaunchAdapt_umap(ctg)
% Launch adapter: build mdlObj_umap from the categorical hub. Auto-discovered
% by nexLaunch_registry (figType = "umap"). The ctg rides the Parent slot;
% nexon and source dfID come off the hub (ctg.nexon, ctg.dfID_source).
%
% Flow: Fit -> Transform writes the projected dfID (umap_<source>) into the
% DTS; the umap figure's "-> StateSpace" button then launches
% nexObj_stateSpace on that output, scoped by the same ctg.
%
% Set nPCAComponents > 0 in the fit cfg panel before Fit to enable the
% internal PCA -> UMAP dimensionality reduction path.
    obj = mdlObj_umap(ctg, [], ctg.dfID_source);
end
