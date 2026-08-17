function nexFigure_stateSpace(nexObj)
    C = nexObj.nexon.settings.Colors;

    % Right-column geometry (all panels share this width)
    xRight  = 610;
    wRight  = 355;   % outer scrollable container width
    wInner  = 340;   % inner panel width (wRight - 2*pad)
    xInner  = 5;

    % Panel heights
    hAni    = 90;
    hWin    = 130;   % windowCfg placeholder — rebuilt by buildSTATE
    hBus    = 275;   % each selectionBus (Collector / Domain / Pointer)
    hPool   = 155;   % pooling config panel
    gap     = 5;

    % Bottom-to-top Y positions inside the scrollable container
    yPtr  = xInner;
    yDom  = yPtr  + hBus  + gap;
    yColl = yDom  + hBus  + gap;
    yWin  = yColl + hBus  + gap;
    yAni  = yWin  + hWin  + gap;
    yPool = yAni  + hAni  + gap;
    hTotal = yPool + hPool + gap;

    %% Figure
    nexObj.Figure.fh = uifigure("Position", [100, 500, 975, 680], "Color", [0,0,0]);

    %% panel0 — scatter3 canvas
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh, ...
        "Position", [5, 5, 600, 640], "BackgroundColor", [0,0,0]);
    nexObj.Figure.panel0.tiles.t  = tiledlayout(nexObj.Figure.panel0.ph, 1, 1);
    nexObj.Figure.panel0.tiles.ax = nexttile(nexObj.Figure.panel0.tiles.t);
    ax = nexObj.Figure.panel0.tiles.ax;
    % canvas: full point cloud.
    % canvas_tracker: struct of per-VW-group scatter3 handles, managed by rebuildTrackers().
    nexObj.Figure.panel0.tiles.graphics.canvas         = scatter3(ax, [], [], [], ...
        100, C.cyberGreen, "filled");
    nexObj.Figure.panel0.tiles.graphics.canvas_tracker = struct();
    colorAx_green(ax);
    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path, ...
        "Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh, CT);

    %% Right scrollable container
    ctrl.ph = uipanel(nexObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 640], ...
        "BackgroundColor", [0,0,0], ...
        "Scrollable",      "on");

    %% aniCfg — animation parameters (stride, etc.)
    entryArgs.entryHeightScaler=4;
    pan_ani.ph = uipanel(ctrl.ph, ...
        "Position", [xInner, yAni, wInner, hAni], "BackgroundColor", [0,0,0], "Scrollable","on");
    nexObj.Figure.panel_ani = nexObj_cfgPanel_v2(nexObj, nexObj.cfg.aniCfg, pan_ani, ...
        nexObj.cfg.aniCfg.entryParams, str2func("cfgEntryChanged_v2"), entryArgs);

    %% windowCfg — DF_postOp.ptr axis panel (Val / Sta / Stp per axis)
    % DF_postOp.ptr is a nexObj_ptr handle — breakoutAxisFields captures it
    % by reference, so spinner callbacks update it in-place with no orphaning.
    % This is the user-facing control for setting dimension position and window.
    pan_win.ph = uipanel(ctrl.ph, ...
        "Position",        [xInner, yWin, wInner, hWin], ...
        "BackgroundColor", [0,0,0], ...
        "Scrollable",      "on", ...
        "Title",           "Window", ...
        "ForegroundColor", C.cyberGreen);
    hasPtr = ~isempty(nexObj.DF_postOp) ...
          && isprop(nexObj.DF_postOp, 'ptr') ...
          && ~isempty(nexObj.DF_postOp.ptr);
    if hasPtr
        nexObj.Figure.windowCfgPanel = nexObj_axisPanel( ...
            nexObj, nexObj.DF_postOp.ptr, pan_win);
    else
        nexObj.Figure.windowCfgPanel = pan_win;
    end

    %% Collector — View selectionBus (AVG / VW / CLR)
    % maxSels = [] → each key: Max = length(selKeys.(key)).
    % refreshVW() updates VW.Max after AVG is populated.
    pan_coll.ph = uipanel(ctrl.ph, ...
        "Position", [xInner, yColl, wInner, hBus], "BackgroundColor", [0,0,0], "Scrollable", "on");
    nexObj.Figure.panel_collector = nexObj_listCfgPanel(nexObj.nexon, pan_coll, ...
        nexObj.collector.View, []);

    % Override SRC callback so changing source updates nexObj.AVG immediately.
    if isfield(nexObj.collector.View.listBoxes, 'SRC') ...
            && ~isempty(nexObj.collector.View.listBoxes.SRC)
        nexObj.collector.View.listBoxes.SRC.Callback = @(s, ~) nexObj.onSRCChanged(s);
    end

    %% Domain — selectionBus (F / D1 / ANI)
    % F: multi-select, Max=3 (scatter3 X/Y/Z).  D1: single.  ANI: single.
    pan_dom.ph = uipanel(ctrl.ph, ...
        "Position", [xInner, yDom, wInner, hBus], "BackgroundColor", [0,0,0], "Scrollable", "on");
    nexObj.Figure.panel_domain = nexObj_listCfgPanel(nexObj.nexon, pan_dom, ...
        nexObj.collector.Domain, [3, 1, 1]);

    %% Pointer — selectionBus (one listbox per DF.ax dimension)
    % maxSels = [] → full multi-select per axis (needed for animated axis and
    % for comparing trajectories across multiple secondary values simultaneously).
    if ~isempty(nexObj.collector.Pointer)
        pan_ptr.ph = uipanel(ctrl.ph, ...
            "Position", [xInner, yPtr, wInner, hBus], "BackgroundColor", [0,0,0], "Scrollable", "on");
        nexObj.Figure.panel_pointer = nexObj_listCfgPanel(nexObj.nexon, pan_ptr, ...
            nexObj.collector.Pointer, []);
    end

    %% UI controls — top bar
    nexObj.Figure.playButton = uibutton("state", ...
        "Parent",           nexObj.Figure.fh, ...
        "Position",         [5, 650, 25, 25], ...
        "BackgroundColor",  [0,0,0], ...
        "Tooltip",          "Play / Pause", ...
        "ValueChangedFcn",  @(~,~) nexObj.startPlayer());

    nexObj.Figure.buildSTATEButton = uibutton(nexObj.Figure.fh, ...
        "Position",        [35, 650, 80, 25], ...
        "BackgroundColor", [0,0,0], ...
        "FontColor",       C.cyberGreen, ...
        "Text",            "Build STATE", ...
        "Tooltip",         "Compile STAT/AVG/DF into STATE matrix", ...
        "ButtonPushedFcn", @(~,~) nexObj.buildSTATE());

    nexFigure_addAvgControls(nexObj, nexObj.Figure.fh, 125, 650, 25);

    nexObj.Figure.refreshButton = uibutton(nexObj.Figure.fh, ...
        "Position",        [220, 650, 60, 25], ...
        "BackgroundColor", [0,0,0], ...
        "FontColor",       C.cyberGreen, ...
        "Text",            "Refresh", ...
        "Tooltip",         "Apply Domain bus (F/D1/ANI) and re-visualize from cached STATE", ...
        "ButtonPushedFcn", @(~,~) nexObj.applyDomainBus());

    %% Pooling — pool map configuration
    pan_pool.ph = uipanel(ctrl.ph, ...
        "Position", [xInner, yPool, wInner, hPool], "BackgroundColor", [0,0,0], "Scrollable", "on");
    nexObj.Figure.panel_pool = nexObj_poolCfgPanel_v2(nexObj, pan_pool, str2func("poolCfgEntryChanged"));
    nexObj.applyHeadline();
end
