function obj = nexLaunchAdapt_lda(ctg)
% Launch adapter: build mdlObj_lda from the categorical hub. Auto-discovered
% by nexLaunch_registry (figType = "lda").
%
% Flow: select a target Y column in the Target panel, Fit, then Run CV to
% store a labelled result. The "-> Bar" button launches nexObj_bar for
% comparing multiple CV runs side-by-side as a nested bar chart.
    obj = mdlObj_lda(ctg, [], ctg.dfID_source);
end
