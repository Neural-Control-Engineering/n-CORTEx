function obj = nexLaunchAdapt_bar(ctg) %#ok<INUSD>
% Launch adapter: open a standalone nexObj_bar. Auto-discovered by
% nexLaunch_registry (figType = "bar").
%
% Launches without a source — wire to an mdlObj after the fact via
% mdlObj.Partners.viewer = obj, or use the "Open Viewer" button on any
% model figure (e.g. nexFigure_lda) which connects automatically.
    obj = nexObj_bar(ctg.nexon);
end
