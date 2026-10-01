function launchButton = nexFigure_addLaunchControls(parent, mdlObj, rowPos, bgColor, fgColor)
% Build a generic "pick a viewer type, launch it" control for any mdlObj
% figure — dropdown (types from nexLaunch_registryMdl) + Launch button,
% sharing one row. Replaces the old hardcoded "-> Bar" button pattern
% (nexFigure_lda_openViewer) so every mdlObj figure gets every registered
% mdlObj-sourced viewer type for free, with no per-figure code — adding a
% new viewer type means only dropping a new nexLaunchAdaptMdl_<figType>.m
% file, never touching this function or any mdlObj figure file.
%
%   parent  : uipanel/uifigure to place the controls in.
%   mdlObj  : the live mdlObj this launcher is attached to.
%   rowPos  : [x, y, w, h] — bounding rect the pair occupies (same h as hBtn).
%   bgColor : background colour.
%   fgColor : foreground / text colour.
%
% Writes mdlObj.Figure.launchTypeDropdown and mdlObj.Figure.launchButton.
% The launched viewer is stored at mdlObj.Partners.viewer — same slot
% nexFigure_lda_openViewer used, so any existing code reading
% mdlObj.Partners.viewer (e.g. wireModelSource's own lazy RESULTS-stub
% registration) keeps working unchanged.

    x = rowPos(1); y = rowPos(2); w = rowPos(3); h = rowPos(4);
    wBtn = 70;
    wDD  = w - wBtn - 5;

    types = string(fieldnames(nexLaunch_registryMdl()))';
    if isempty(types), types = "(none)"; end

    dd = uidropdown(parent, ...
        "Position",        [x, y, wDD, h], ...
        "Items",           cellstr(types), ...
        "BackgroundColor", bgColor, ...
        "FontColor",       fgColor);

    launchButton = uibutton(parent, ...
        "Position",        [x + wDD + 5, y, wBtn, h], ...
        "Text",            "Launch", ...
        "BackgroundColor", bgColor, ...
        "FontColor",       fgColor, ...
        "ButtonPushedFcn", @(~,~) onLaunch());

    mdlObj.Figure.launchTypeDropdown = dd;
    mdlObj.Figure.launchButton       = launchButton;

    function onLaunch()
        figType = string(dd.Value);
        reg     = nexLaunch_registryMdl();
        if figType == "(none)" || ~isfield(reg, figType), return; end
        if ~isstruct(mdlObj.Partners), mdlObj.Partners = struct(); end
        mdlObj.Partners.viewer = reg.(figType)(mdlObj);
    end
end
