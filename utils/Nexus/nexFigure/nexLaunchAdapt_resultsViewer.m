function obj = nexLaunchAdapt_resultsViewer(ctg) %#ok<INUSD>
% Launch adapter: open a standalone nexObj_resultsViewer. Auto-discovered
% by nexLaunch_registry (figType = "resultsViewer").
%
% Launches without a source — wire to an mdlObj after the fact via
% mdlObj.Partners.viewer = obj, or use the "Open Results Viewer" button
% on any model figure (e.g. nexFigure_lda) which connects automatically.
    obj = nexObj_resultsViewer(ctg.nexon);
end
