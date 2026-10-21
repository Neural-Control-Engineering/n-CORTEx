function nexFigure_monoGram(nexObj)
    C     = nexObj.nexon.settings.Colors;
    GREEN = C.cyberGreen;
    BLACK = [0 0 0];

    % ── Layout constants ─────────────────────────────────────────────────
    % wRight/wInner standardized to nexFigure_stateSpace's sidebar width
    % (same selectionBus panel content — Collector/Domain/Pointer — was
    % cramped at the old 190/180). Figure width grows by the same delta so
    % the canvas panel's own geometry (xRight, canvas width) is untouched.
    % wRight/wInner widened again for Domain's 3rd listbox (REG, added
    % alongside D1/ANI) — nexObj_listCfgPanel now divides panel width by
    % (nKeys+0.3) instead of a fixed 2.3, so a 3rd column at the OLD width
    % squeezed all three into what used to fit two. Scaled by that same
    % ratio (3.3/2.3) to restore each listbox's original per-box width.
    xRight = 810;  wRight = 430;  wInner = 420;  xInner = 5;  gap = 5;

    hVis  = 150;
    hWin  = 155;
    hPool = 130;
    hPtr  = 220;
    hColl = 220;
    hDom  = 200;

    % Bottom-to-top stacking order matches nexFigure_stateSpace: Pointer,
    % then Domain, then Collector (Collector sits directly below Pool),
    % with Pool at the very top rather than sandwiched below Pointer —
    % Pool is the axis-shape control, so it reads more naturally above the
    % buses whose contents it determines.
    yVis  = xInner;
    yWin  = yVis  + hVis  + gap;
    yPtr  = yWin  + hWin  + gap;
    yDom  = yPtr  + hPtr  + gap;
    yColl = yDom  + hDom  + gap;
    yPool = yColl + hColl + gap;

    % ── Figure ───────────────────────────────────────────────────────────
    nexObj.Figure.fh = uifigure("Position", [100, 200, 1245, 900], "Color", BLACK);

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

    % Construction-time default -- the ORIGINAL monoGram colormap,
    % reinstated for every source EXCEPT a sigThreshold-bearing (p-value)
    % RESULTS row. nexVisualization_monoGram.m switches to the cleaner
    % black->cyberGreen->white gradient (nexVis_sequentialColormap) on
    % every render where hasSigThreshold is true, and back to this one
    % otherwise -- this is just the safe default before that first render
    % knows which case applies.
    %
    % Set on ax directly, NOT nexObj.Figure.fh: fh is a uifigure, and
    % colormap(fig, cmap) does not reliably propagate down to a uifigure's
    % child axes the way it does for a classic figure() -- confirmed
    % directly (figure-level set alone left the canvas unchanged).
    % colorAx_green(ax) above already styles THIS axes directly for the
    % same underlying reason.
    colormap(ax, nexVis_legacyCyberGreenColormap(nexObj.nexon));

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

    % Significance-threshold spinner -- manually added (not auto-generated
    % via nexObj_cfgPanel_v2/visCfgEntryChanged_v2, since its backing
    % store is a per-row RESULTS.sigThreshold column, not
    % cfg.visCfg.entryParams -- see onSigThresholdChanged) but placed in
    % the SAME scrollable panel, continuing breakoutCfgFields_v4's own
    % label/spinner step convention (yStepScaler=25, entryHeight=20, m
    % stepping by 2 per field; 7 fields above it -- zLim_low/high,
    % cLim_low/high, component, scale, fScale -- end at m=15) so it reads
    % as one more Vis control, not a bolted-on extra. Hidden until
    % nexVisualization_monoGram finds a RESULTS row with a sigThreshold
    % column (only meaningful then) and pushes both Visible and Value.
    yStepSig = 25; entryHeightSig = 20; mSig = 15;
    panelWVis = pan_vis.ph.Position(3);
    nexObj.Figure.panel_vis.editFields.sigThreshold.Label = uitextarea(pan_vis.ph, ...
        "Value",           "sigThreshold (p <)", ...
        "Position",        [4, 5 + (mSig+1)*yStepSig, panelWVis*0.95, entryHeightSig], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, "Visible", "off");
    nexObj.Figure.panel_vis.editFields.sigThreshold.uiField = uispinner(pan_vis.ph, ...
        "Position",        [4, 5 + mSig*yStepSig, panelWVis*0.8, entryHeightSig], ...
        "Value", 0.05, "Step", 0.005, "Limits", [0, 1], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, "Visible", "off", ...
        "ValueChangedFcn", @(s,~) nexObj.onSigThresholdChanged(s));

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
    % VW: wired to onVWChanged, NOT the generic listCfgEntryChanged default --
    % VW selects which RESULTS row(s) are displayed (e.g. a CTG stratum),
    % and different rows can disagree on an axis's composition/order (e.g.
    % region coverage differing by stratum). The generic default only
    % re-renders; onVWChanged also re-syncs Pointer.selKeys to the newly-
    % active row(s), which is what was missing (see onVWChanged's header).
    if isfield(nexObj.collector.View.listBoxes, 'VW') ...
            && ~isempty(nexObj.collector.View.listBoxes.VW)
        nexObj.collector.View.listBoxes.VW.Callback = @(s,~) nexObj.onVWChanged(s);
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
        nexObj.collector.Domain.listBoxes.D1.Callback = @(s,~) nexObj.onD1Changed(s);
    end
    % ANI: single-select, updates domain.animate and triggers visualize
    if isfield(nexObj.collector.Domain.listBoxes, 'ANI') ...
            && ~isempty(nexObj.collector.Domain.listBoxes.ANI)
        nexObj.collector.Domain.listBoxes.ANI.Max      = 1;
        nexObj.collector.Domain.listBoxes.ANI.Callback = @(s,~) nexObj.onANIChanged(s);
    end
    % REG: single-select, cross-sample registration identity axis for
    % nexOp_compileSTAT's co-axis alignment (default "None" = no-op)
    if isfield(nexObj.collector.Domain.listBoxes, 'REG') ...
            && ~isempty(nexObj.collector.Domain.listBoxes.REG)
        nexObj.collector.Domain.listBoxes.REG.Max      = 1;
        nexObj.collector.Domain.listBoxes.REG.Callback = @(s,~) nexObj.onREGChanged(s);
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

    nexFigure_addAvgControls(nexObj, nexObj.Figure.fh, 35, 878, 20);
    % addAvgControls consumes 140px (60 spinner + 5 gap + 75 button)
    % starting at x=35, i.e. through x=175 — reloadButton must start past
    % that, not at x=130 (which overlapped the Report AVG button outright).
    nexObj.Figure.reloadButton = uibutton(nexObj.Figure.fh, ...
        "Position",        [185, 878, 70, 20], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, ...
        "Text",            "Reload DF", ...
        "Tooltip",         "Re-read DF from router and refresh", ...
        "ButtonPushedFcn", @(~,~) nexObj.reloadFromRouter());

    nexObj.Figure.homeButton = uibutton(nexObj.Figure.fh, ...
        "Position",        [265, 878, 60, 20], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, ...
        "Text",            "Home", ...
        "Tooltip",         "Set Z/C limits to the current surface's actual data range", ...
        "ButtonPushedFcn", @(~,~) nexObj.homeLimits());

    nexObj.applyHeadline();
end

