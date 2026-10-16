function btn = nexFigure_addCompileControl(parent, mdlObj, rowPos, bgColor, fgColor)
% Build the Compile button — runs mdlObj.precompileSTAT(), which
% establishes fitSentinel and refreshes the Pointer bus's REG-axis
% options to the true canonical set, WITHOUT yet applying pooling or
% building the final STAT table. Adjust your Pointer/pMap subselection
% (e.g. groupBy='region', pick specific regions) after pressing this,
% then Fit — the selection survives untouched into the fit instead of
% being silently reset (see mdlObject.precompileSTAT/compileSTAT and
% invalidatePrecompile for when the cache this button fills gets
% cleared automatically).
%
%   rowPos  : [x, y, w, h] — bounding rect the button occupies.
%   bgColor : background colour (e.g. [0 0 0])
%   fgColor : foreground / text colour (e.g. cyberGreen)

    btn = uibutton(parent, ...
        "Position",        rowPos, ...
        "Text",            "Compile", ...
        "BackgroundColor", bgColor, ...
        "FontColor",       fgColor, ...
        "ButtonPushedFcn", @(~,~) mdlObj.precompileSTAT());
end
