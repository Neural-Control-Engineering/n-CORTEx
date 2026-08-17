function nexPanel_launcher(nexon)
% nexPanel_launcher  Standalone figure-launcher window attached to nexon.
%
% Creates a small floating window with nexLaunch_panel (all DTS sources,
% no filter) and stores it at nexon.console.launcher. Called from
% startNexus so the launcher is available in both online and offline
% contexts without needing the npxls control panel to be open.

    C = nexon.settings.Colors; GREEN = C.cyberGreen; BLACK = [0 0 0];

    fh = uifigure("Name","figure launcher","Position",[900,500,390,285],"Color",BLACK);
    ph = uipanel(fh,"Position",[5,5,185,275], ...
        "BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","INSPECT");
    nexLaunch_panel(ph, nexon, []);

    phExt = uipanel(fh,"Position",[200,5,185,275], ...
        "BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","EXTRACT");
    nexLaunch_extractPanel(phExt, nexon);

    nexon.console.launcher = struct("fh", fh, "ph", ph, "phExt", phExt);
end
