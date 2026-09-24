function [btn, cbOver, cbTrial, edLabel] = nexFigure_addTransformControls(parent, mdlObj, rowPos, bgColor, fgColor)
% Build the label field + Transform->DTS button + overwrite/current-trial
% checkboxes.
%
%   rowPos  : [x, y, w, h] — bounding rect for the button/checkbox row.
%             An additional label-field row is drawn just ABOVE this rect
%             (at y+h onward) — callers must reserve nexFigure_addTransformControls.LABEL_ROW_HEIGHT
%             extra vertical space (see constant below) plus their usual
%             inter-row gap when stacking whatever sits above this control.
%   bgColor : background colour (e.g. [0 0 0])
%   fgColor : foreground / text colour (e.g. cyberGreen)
%
% Returns btn, cbOver (overwrite), cbTrial (current trial only), edLabel
% (the label text field). The button callback reads all three at click
% time and passes the sanitized label through to scaleApply_transform as
% outputLabel — a full override of the output artifact name (not a
% suffix), so typing a label writes to exactly that patch ID rather than
% mdlObj's default. Left blank, behavior is unchanged from before this
% field existed (uses the default dfID_target-derived name).

    x = rowPos(1);  y = rowPos(2);
    w = rowPos(3);  h = rowPos(4);

    hLabel = 20;  % nexFigure_addTransformControls.LABEL_ROW_HEIGHT — callers reserve this + their gap above rowPos
    edLabel = uieditfield(parent, "text", ...
        "Position",    [x, y + h + 2, w, hLabel], ...
        "Placeholder", "patch ID (optional — overrides default name)", ...
        "BackgroundColor", [0.12 0.12 0.12], ...
        "FontColor",   fgColor, ...
        "ValueChangedFcn", @(src,~) onLabelChanged(src));
    onLabelChanged(edLabel);  % seed mdlObj.lastOutputLabel from whatever the field starts with (normally blank)

    wBtn = round(w * 0.62);    % ~62 % of row width
    xChk = x + wBtn + 5;
    wChk = w - wBtn - 5;
    hChk = 13;

    btn = uibutton(parent, ...
        "Position",        [x, y, wBtn, h], ...
        "Text",            "Transform->DTS", ...
        "BackgroundColor", bgColor, ...
        "FontColor",       fgColor, ...
        "ButtonPushedFcn", @onTransform);

    cbOver = uicheckbox(parent, ...
        "Position",  [xChk, y + h - hChk - 1, wChk, hChk], ...
        "Text",      "overwrite", ...
        "Value",     false, ...
        "FontColor", fgColor, ...
        "FontSize",  9);

    cbTrial = uicheckbox(parent, ...
        "Position",  [xChk, y + 2, wChk, hChk], ...
        "Text",      "cur trial", ...
        "Value",     false, ...
        "FontColor", fgColor, ...
        "FontSize",  9);

    function label = sanitizedLabel_()
        label = regexprep(strtrim(edLabel.Value), '[^a-zA-Z0-9_]', '_');
    end

    function onLabelChanged(~)
        % Registers on every commit (Enter / focus-out), independent of
        % ever pressing Transform — e.g. Save right after typing a label
        % picks it up too. scaleApply_transform also sets this from
        % whatever label it actually ran with, so the two stay
        % consistent whichever one last touched it.
        mdlObj.lastOutputLabel = string(sanitizedLabel_());
    end

    function onTransform(~, ~)
        mdlObj.scaleApply_transform([], cbOver.Value, cbTrial.Value, sanitizedLabel_());
    end
end
