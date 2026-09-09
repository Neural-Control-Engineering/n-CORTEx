function obj = nexLaunchAdapt_lda(ctg)
% Launch adapter: build mdlObj_lda from the categorical hub. Auto-discovered
% by nexLaunch_registry (figType = "lda").
%
% Flow: select a target Y column in the Target panel, Fit, then Run CV to
% store a labelled result. The "Open Results Viewer" button launches
% nexObj_resultsViewer for comparing multiple CV runs side-by-side.
    obj = mdlObj_lda(ctg, [], ctg.dfID_source);
end
