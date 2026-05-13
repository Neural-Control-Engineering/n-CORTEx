function nexFigure_monoGram(nexObj)
    C     = nexObj.nexon.settings.Colors;
    GREEN = C.cyberGreen;
    BLACK = [0 0 0];

    % ── Layout constants ─────────────────────────────────────────────────
    xRight = 810;  wRight = 190;  wInner = 180;  xInner = 5;  gap = 5;

    hVis  = 150;
    hWin  = 155;
    hPool = 130;
    hPtr  = 220;
    hColl = 220;
    hDom  = 200;

    yVis  = xInner;
    yWin  = yVis  + hVis  + gap;
    yPool = yWin  + hWin  + gap;
    yPtr  = yPool + hPool + gap;
    yColl = yPtr  + hPtr  + gap;
    yDom  = yColl + hColl + gap;

    % ── Figure ───────────────────────────────────────────────────────────
    nexObj.Figure.fh = uifigure("Position", [100, 200, 1005, 900], "Color", BLACK);

    % ── Canvas panel ─────────────────────────────────────────────────────
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh, ...
        "Position", [5, 5, 800, 870], "BackgroundColor", BLACK);
    nexObj.Figure.panel0.tiles.t  = tiledlayout(nexObj.Figure.panel0.ph, 1, 1);
    nexObj.Figure.panel0.tiles.ax = nexttile(nexObj.Figure.panel0.tiles.t);

    % Seed surf canvas from current D1 selection
    ax = nexObj.Figure.panel0.tiles.ax;
    try
        domSel = nex_returnSelectionMask(nexObj.collector.Domain);
        d1Vals = string(domSel.D1);
        rowKey = d1Vals(1);  colKey = d1Vals(2);
        Y = nexObj.DF_postOp.ax.(rowKey);
        X = nexObj.DF_postOp.ax.(colKey);
        ptr = nexObj.DF_postOp.ptr;
        Z   = squeeze(sliceDF(nexObj.DF_postOp.df, ptr, [rowKey, colKey], "range"));
        if ptr.(rowKey).dim > ptr.(colKey).dim, Z = Z'; end
    catch
        Y = 1:4;  X = 1:4;  Z = nan(4, 4);
    end
    nexObj.Figure.panel0.tiles.graphics.canvas = surf(ax, X, Y, Z, "EdgeColor", "none");
    colorAx_green(ax);

    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path, ...
        "Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh, CT);

    % ── Right scrollable panel ────────────────────────────────────────────
    ctrl.ph = uipanel(nexObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 870], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");

    % Vis cfg
    pan_vis.ph = uipanel(ctrl.ph, ...
        "Position",        [xInner, yVis, wInner, hVis], ...
        "BackgroundColor", BLACK, "Scrollable", "on");
    nexObj.Figure.panel_vis = nexObj_cfgPanel_v2(nexObj, nexObj.cfg.visCfg, pan_vis, ...
        nexObj.cfg.visCfg.entryParams, str2func("visCfgEntryChanged_v2"), []);

    % Window — axis pointer
    pan_win.ph = uipanel(ctrl.ph, ...
        "Position",        [xInner, yWin, wInner, hWin], ...
        "BackgroundColor", BLACK, "Scrollable", "on", ...
        "Title", "Window", "ForegroundColor", GREEN);
    DF = nexObj.DF_postOp;
    if ~isempty(DF) && ~isempty(DF.ptr)
        nexObj.Figure.panel_win = nexObj_axisPanel(nexObj, DF.ptr, pan_win);
    else
        nexObj.Figure.panel_win = pan_win;
    end

    % Pooling
    pan_pool.ph = uipanel(ctrl.ph, ...
        "Position",        [xInner, yPool, wInner, hPool], ...
        "BackgroundColor", BLACK, "Scrollable", "on");
    nexObj.Figure.panel_pool = nexObj_poolCfgPanel_v2(nexObj, pan_pool, ...
        str2func("poolCfgEntryChanged"));

    % Pointer bus
    nexObj.buildPointerPanel(ctrl.ph, [xInner, yPtr, wInner, hPtr]);

    % Collector — View (SRC / VW / CLR)
    pan_coll.ph = uipanel(ctrl.ph, ...
        "Position",        [xInner, yColl, wInner, hColl], ...
        "BackgroundColor", BLACK, "Scrollable", "on");
    nexObj.Figure.panel_collector = nexObj_listCfgPanel(nexObj.nexon, pan_coll, ...
        nexObj.collector.View, []);
    % SRC: single-select, wired to applySRC
    if isfield(nexObj.collector.View.listBoxes, 'SRC') ...
            && ~isempty(nexObj.collector.View.listBoxes.SRC)
        nexObj.collector.View.listBoxes.SRC.Max      = 1;
        nexObj.collector.View.listBoxes.SRC.Callback = @(s,~) nexObj.onSRCChanged(s);
    end

    % Collector — Domain (D1 multi-select, ANI single-select)
    pan_dom.ph = uipanel(ctrl.ph, ...
        "Position",        [xInner, yDom, wInner, hDom], ...
        "BackgroundColor", BLACK, "Scrollable", "on", ...
        "Title", "Domain", "ForegroundColor", GREEN);
    nexObj.Figure.panel_domain = nexObj_listCfgPanel(nexObj.nexon, pan_dom, ...
        nexObj.collector.Domain, []);
    % D1: multi-select (up to 2), triggers visualize
    if isfield(nexObj.collector.Domain.listBoxes, 'D1') ...
            && ~isempty(nexObj.collector.Domain.listBoxes.D1)
        nexObj.collector.Domain.listBoxes.D1.Max      = 2;
        nexObj.collector.Domain.listBoxes.D1.Callback = @(s,~) mgm_D1Changed(nexObj, s);
    end
    % ANI: single-select, updates domain.animate and triggers visualize
    if isfield(nexObj.collector.Domain.listBoxes, 'ANI') ...
            && ~isempty(nexObj.collector.Domain.listBoxes.ANI)
        nexObj.collector.Domain.listBoxes.ANI.Max      = 1;
        nexObj.collector.Domain.listBoxes.ANI.Callback = @(s,~) mgm_ANIChanged(nexObj, s);
    end

    % ── Top-bar controls ─────────────────────────────────────────────────
    nexObj.Figure.playButton = uibutton("state", ...
        "Parent",           nexObj.Figure.fh, ...
        "Position",         [5, 878, 25, 20], ...
        "BackgroundColor",  BLACK, ...
        "Tooltip",          "Play / Pause", ...
        "ValueChangedFcn",  @(~,~) nexObj.startPlayer());

    nexObj.Figure.dfIDEditField = uieditfield(nexObj.Figure.fh, ...
        "BackgroundColor", BLACK, "FontColor", GREEN, ...
        "Position",        [855, 878, 145, 20], ...
        "Value",           char(nexObj.dfID_source), ...
        "Tooltip",         "Source dfID", ...
        "ValueChangedFcn", @(src,evt) nexUpdate_dfID(src, evt, nexObj.nexon, nexObj));

    nexObj.Figure.reportAvgButton = uibutton(nexObj.Figure.fh, ...
        "Position",        [35, 878, 110, 20], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, ...
        "Text",            "Report Average", ...
        "Tooltip",         "Group STAT and store averaged result in RESULTS", ...
        "ButtonPushedFcn", @(~,~) nexObj.reportAverage());

    nexObj.Figure.reloadButton = uibutton(nexObj.Figure.fh, ...
        "Position",        [150, 878, 70, 20], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, ...
        "Text",            "Reload DF", ...
        "Tooltip",         "Re-read DF from router and refresh", ...
        "ButtonPushedFcn", @(~,~) nexObj.reloadFromRouter());

    nexObj.applyHeadline();
end

% ── Domain callbacks ──────────────────────────────────────────────────────

function mgm_D1Changed(nexObj, lb)
    nexObj.collector.Domain.selections.D1 = lb.Value;
    nexObj.visualize();
end

function mgm_ANIChanged(nexObj, lb)
    nexObj.collector.Domain.selections.ANI = lb.Value;
    aniKeys = nexObj.collector.Domain.selKeys.ANI;
    if ~isempty(lb.Value) && ~isempty(aniKeys)
        nexObj.domain.animate = string(aniKeys(lb.Value(end)));
    end
    nexObj.visualize();
end
