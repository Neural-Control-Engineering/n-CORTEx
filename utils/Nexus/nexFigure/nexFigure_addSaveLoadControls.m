function [btnSave, btnLoad] = nexFigure_addSaveLoadControls(parent, mdlObj, rowPos, bgColor, fgColor)
% Build Save | Load buttons for any mdlObj figure, split across rowPos width.
%   rowPos  : [x, y, w, h] — bounding rect the pair occupies (same h as hBtn).
%   bgColor : background colour.
%   fgColor : foreground / text colour.

    x = rowPos(1); y = rowPos(2); w = rowPos(3); h = rowPos(4);
    wHalf = floor((w - 5) / 2);

    btnSave = uibutton(parent, ...
        "Position",        [x, y, wHalf, h], ...
        "Text",            "Save", ...
        "BackgroundColor", bgColor, ...
        "FontColor",       fgColor, ...
        "ButtonPushedFcn", @(~,~) onSave());

    function onSave()
        % uniqueID is "<datestamp>_<suffix>" — suffix is normally the
        % current time, but if the last Transform used a patch-ID label
        % (mdlObj.lastOutputLabel), use that instead so the saved fit's
        % folder name reflects what conditions it was last transformed
        % under rather than an opaque timestamp.
        dateStamp = char(datetime("now", "Format", "yyyyMMdd"));
        if isprop(mdlObj, 'lastOutputLabel') && strlength(mdlObj.lastOutputLabel) > 0
            suffix = char(mdlObj.lastOutputLabel);
        else
            suffix = char(datetime("now", "Format", "HHmmss"));
        end
        mdlObj.saveFit(sprintf('%s_%s', dateStamp, suffix));
    end

    btnLoad = uibutton(parent, ...
        "Position",        [x + wHalf + 5, y, wHalf, h], ...
        "Text",            "Load", ...
        "BackgroundColor", bgColor, ...
        "FontColor",       fgColor, ...
        "ButtonPushedFcn", @(~,~) mdlObj.loadFit([]));
end
