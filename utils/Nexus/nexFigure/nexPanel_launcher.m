function nexPanel_launcher(nexon)
% nexPanel_launcher  Standalone figure-launcher window attached to nexon.
%
% Creates a small floating window with nexLaunch_panel (all DTS sources,
% no filter) and stores it at nexon.console.launcher. Called from
% startNexus so the launcher is available in both online and offline
% contexts without needing the npxls control panel to be open.

    C = nexon.settings.Colors; GREEN = C.cyberGreen; BLACK = [0 0 0];

    fh = uifigure("Name","figure launcher","Position",[900,500,390,305],"Color",BLACK);

    scroll = uipanel(fh,"Position",[0,0,390,305],"Scrollable","on", ...
        "BackgroundColor",BLACK,"BorderType","none");

    ph = uipanel(scroll,"Position",[5,5,185,275], ...
        "BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","INSPECT");
    nexLaunch_panel(ph, nexon, []);

    phExt = uipanel(scroll,"Position",[200,5,185,275], ...
        "BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","EXTRACT");
    nexLaunch_extractPanel(phExt, nexon);

    phTools = uipanel(scroll,"Position",[395,5,185,275], ...
        "BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","TOOLS");
    uibutton(phTools,"Text","Ephys Atlas","Position",[5,222,160,28], ...
        "BackgroundColor",BLACK,"FontColor",GREEN, ...
        "ButtonPushedFcn",@(~,~) raiseOrCreate());

    nexon.console.launcher = struct("fh",fh,"ph",ph,"phExt",phExt,"phTools",phTools);

    function raiseOrCreate()
        if isfield(nexon.console,'ATLAS') && isvalid(nexon.console.ATLAS)
            nexon.console.ATLAS.raise();
        else
            nexon.console.ATLAS = nexObj_ephysAtlas(nexon);
        end
    end
end
