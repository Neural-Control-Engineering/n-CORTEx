function nexFigure_monoGraph(nexObj)
    C     = nexObj.nexon.settings.Colors;
    GREEN = C.cyberGreen;
    BLACK = [0 0 0];

    % Right panel geometry
    xRight = 810;
    wRight = 250;
    wInner = 240;
    xInner = 5;
    gap    = 5;

    % Panel heights (bottom-to-top stacking)
    hVis  = 150;
    hWin  = 155;
    hPool = 155;
    hPtr  = 260;
    hColl = 260;
    hDom  = 150;

    yVis  = xInner;
    yWin  = yVis  + hVis  + gap;
    yPool = yWin  + hWin  + gap;
    yPtr  = yPool + hPool + gap;
    yColl = yPtr  + hPtr  + gap;
    yDom  = yColl + hColl + gap;

    %% Figure
    nexObj.Figure.fh = uifigure("Position", [100, 1060, 1005, 420], "Color", BLACK);

    %% panel0 — main plot canvas
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh, ...
        "Position", [5, 5, 800, 390], "BackgroundColor", BLACK);
    nexObj.Figure.panel0.tiles.t  = tiledlayout(nexObj.Figure.panel0.ph, 1, 1);
    nexObj.Figure.panel0.tiles.ax = nexttile(nexObj.Figure.panel0.tiles.t);

    % Seed canvas with empty line/patch
    DF    = nexObj.DF_postOp;
    domSel = nex_returnSelectionMask(nexObj.collector.Domain);
    d1Vals = string(domSel.D1);
    seedAx = char(d1Vals(1));
    t_axis = DF.ax.(seedAx);
    df_seed = nan(1, numel(t_axis));
    [l, p] = plotWithSEM(nexObj.Figure.panel0.tiles.ax, t_axis, df_seed, [], [1,1,1], []);
    nexObj.Figure.panel0.tiles.graphics.canvas_l = l;
    nexObj.Figure.panel0.tiles.graphics.canvas_p = p;

    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path, ...
        "Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh, CT);
    colorAx_green(nexObj.Figure.panel0.tiles.ax);

    %% Right scrollable container
    ctrl.ph = uipanel(nexObj.Figure.fh, ...
        "Position",   [xRight, 5, wRight, 390], ...
        "BackgroundColor", BLACK, ...
        "Scrollable", "on");

    %% Vis cfg
    pan_vis.ph = uipanel(ctrl.ph, ...
        "Position", [xInner, yVis, wInner, hVis], "BackgroundColor", BLACK, "Scrollable", "on");
    nexObj.Figure.panel_vis = nexObj_cfgPanel_v2(nexObj, nexObj.cfg.visCfg, pan_vis, ...
        nexObj.cfg.visCfg.entryParams, str2func("visCfgEntryChanged_v2"), []);

    %% Window — axis pointer panel
    pan_win.ph = uipanel(ctrl.ph, ...
        "Position",   [xInner, yWin, wInner, hWin], ...
        "BackgroundColor", BLACK, "Scrollable", "on", ...
        "Title", "Window", "ForegroundColor", GREEN);
    if ~isempty(DF) && isfield(DF, 'ptr') && ~isempty(DF.ptr)
        nexObj.Figure.panel_win = nexObj_axisPanel(nexObj, DF.ptr, pan_win);
    else
        nexObj.Figure.panel_win = pan_win;
    end

    %% Pooling
    pan_pool.ph = uipanel(ctrl.ph, ...
        "Position", [xInner, yPool, wInner, hPool], "BackgroundColor", BLACK, "Scrollable", "on");
    nexObj.Figure.panel_pool = nexObj_poolCfgPanel_v2(nexObj, pan_pool, ...
        str2func("poolCfgEntryChanged"));

    %% Pointer — axis value filter for reportSTAT
    nexObj.initPointerBus();
    nexObj.buildPointerPanel(ctrl.ph, [xInner, yPtr, wInner, hPtr]);

    %% Collector — View bus (SRC / VW / CLR)
    pan_coll.ph = uipanel(ctrl.ph, ...
        "Position", [xInner, yColl, wInner, hColl], "BackgroundColor", BLACK, "Scrollable", "on");
    nexObj.Figure.panel_collector = nexObj_listCfgPanel(nexObj.nexon, pan_coll, ...
        nexObj.collector.View, []);
    if isfield(nexObj.collector.View.listBoxes, 'SRC') ...
            && ~isempty(nexObj.collector.View.listBoxes.SRC)
        nexObj.collector.View.listBoxes.SRC.Max      = 1;
        nexObj.collector.View.listBoxes.SRC.Callback = @(s, ~) nexObj.onSRCChanged(s);
    end

    %% Collector — Domain (D1 single-select, ANI single-select)
    pan_dom.ph = uipanel(ctrl.ph, ...
        "Position",        [xInner, yDom, wInner, hDom], ...
        "BackgroundColor", BLACK, "Scrollable", "on", ...
        "Title", "Domain", "ForegroundColor", GREEN);
    nexObj.Figure.panel_domain = nexObj_listCfgPanel(nexObj.nexon, pan_dom, ...
        nexObj.collector.Domain, []);
    if isfield(nexObj.collector.Domain.listBoxes, 'D1') ...
            && ~isempty(nexObj.collector.Domain.listBoxes.D1)
        nexObj.collector.Domain.listBoxes.D1.Max      = 1;
        nexObj.collector.Domain.listBoxes.D1.Callback = @(s, ~) nexObj.onD1Changed(s);
    end
    if isfield(nexObj.collector.Domain.listBoxes, 'ANI') ...
            && ~isempty(nexObj.collector.Domain.listBoxes.ANI)
        nexObj.collector.Domain.listBoxes.ANI.Max      = 1;
        nexObj.collector.Domain.listBoxes.ANI.Callback = @(s, ~) nexObj.onANIChanged(s);
    end

    %% Top-bar controls
    nexObj.Figure.playButton = uibutton('state', ...
        'Parent',           nexObj.Figure.fh, ...
        'Position',         [5, 400, 25, 20], ...
        'BackgroundColor',  BLACK, ...
        'Tooltip',          'Play / Pause', ...
        'ValueChangedFcn',  @(~,~) nexObj.startPlayer());

    nexObj.Figure.dfIDEditField = uieditfield(nexObj.Figure.fh, ...
        "BackgroundColor", BLACK, "FontColor", GREEN, ...
        "Position",        [855, 400, 150, 20], ...
        "Value",           char(nexObj.dfID_source), ...
        "ValueChangedFcn", @(src, evt) nexUpdate_dfID(src, evt, nexObj.nexon, nexObj));

    nexObj.Figure.reportAvgButton = uibutton(nexObj.Figure.fh, ...
        "Position",        [35, 400, 90, 20], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, ...
        "Text",            "Report Average", ...
        "Tooltip",         "Group STAT by AVG selection and store in RESULTS", ...
        "ButtonPushedFcn", @(~,~) nexObj.reportAverage());

    nexObj.Figure.reloadButton = uibutton(nexObj.Figure.fh, ...
        "Position",        [130, 400, 70, 20], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, ...
        "Text",            "Reload DF", ...
        "Tooltip",         "Re-read DF from router and refresh", ...
        "ButtonPushedFcn", @(~,~) nexObj.reloadFromRouter());

    nexObj.applyHeadline();
end

