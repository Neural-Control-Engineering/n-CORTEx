function nexFigure_linear(mdlObj)

    BLACK = [0 0 0];
    nexon = mdlObj.nexon;
    GREEN = nexon.settings.Colors.cyberGreen;

    % ── Layout constants ──────────────────────────────────────────────────
    xRight  = 665;
    wRight  = 260;
    wInner  = 250;
    xInner  = 5;

    hBtn    = 30;
    hFitCfg = 130;
    hPtr    = 200;
    hDomain = 130;
    hTarget = 55;
    hView   = 175;
    gap     = 5;

    yFit    = xInner;
    yFitCfg = yFit    + hBtn    + gap;
    yPtr    = yFitCfg + hFitCfg + gap;
    yDomain = yPtr    + hPtr    + gap;
    yTarget = yDomain + hDomain + gap;
    yView   = yTarget + hTarget + gap;

    % ── Collector init ────────────────────────────────────────────────────

    % View bus (SRC / VW / CLR)
    % SRC — saved fit artifact selector; starts as "fit" (current in-memory fit)
    % VW  — group/row selector for active RESULT; empty until storeResult fires
    % CLR — per-point colorization column; unused until explicitly set
    viewDict.SRC = "fit";
    viewDict.VW  = "";
    viewDict.CLR = "";
    mdlObj.collector.View = nexInit_collectorView(mdlObj, viewDict);

    % Read axes from the model's own source DF — Origin.DF_postOp belongs to the
    % parent categorical and won't contain axes like 'latent' that are produced
    % by an upstream transform (e.g. dPCA).
    srcAx = struct();
    try
        srcDF = dtsIO_readDF(mdlObj.nexon, mdlObj.dfID_source, []);
        if ~isempty(srcDF) && isfield(srcDF, 'ax')
            srcAx = srcDF.ax;
        end
    catch
    end
    if isempty(fieldnames(srcAx))
        try, srcAx = mdlObj.Origin.DF_postOp.ax; catch, end
    end

    % Pointer bus — delegate to base method
    mdlObj.initPointerBus();

    % Domain bus (D1 / FTR)
    try
        axNames = string(fieldnames(srcAx))';
    catch
        axNames = ["t"];
    end
    d1Init  = find(axNames == mdlObj.domain.D1, 1);
    if isempty(d1Init), d1Init = 1; end
    ftrIdx  = find(axNames ~= axNames(d1Init));
    ftrInit = 1;
    if ~isempty(ftrIdx), ftrInit = ftrIdx(1); end
    domainDict.D1  = axNames;
    domainDict.FTR = axNames;
    mdlObj.collector.Domain = buildSelection(mdlObj, domainDict);
    mdlObj.collector.Domain.selections.D1  = d1Init;
    mdlObj.collector.Domain.selections.FTR = ftrInit;

    % ── Figure ────────────────────────────────────────────────────────────
    mdlObj.Figure.fh = uifigure( ...
        "Position", [100, 500, 935, 630], ...
        "Color",    BLACK, ...
        "Name",     sprintf("Linear — %s", mdlObj.dfID_source));

    % ── Canvas (left panel) ───────────────────────────────────────────────
    mdlObj.Figure.panel0.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [5, 5, 655, 620], ...
        "BackgroundColor", BLACK);
    mdlObj.Figure.panel0.tiles.t = tiledlayout( ...
        mdlObj.Figure.panel0.ph, 1, 1, ...
        "TileSpacing", "compact", "Padding", "compact");
    ax = nexttile(mdlObj.Figure.panel0.tiles.t);
    mdlObj.Figure.panel0.tiles.ax = ax;
    ax.Color     = BLACK;
    ax.XColor    = GREEN;
    ax.YColor    = GREEN;
    ax.GridColor = GREEN;
    ax.GridAlpha = 0.12;
    ax.Box       = "on";
    ax.FontSize  = 9;
    grid(ax, "on");
    hold(ax, "on");
    xlabel(ax, 'Y actual',    'Color', GREEN);
    ylabel(ax, 'Y predicted', 'Color', GREEN);
    title(ax, 'Predicted vs Actual  (run Fit to populate)', ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);
    mdlObj.Figure.panel0.tiles.graphics.scatter  = [];
    mdlObj.Figure.panel0.tiles.graphics.identity = [];
    mdlObj.Figure.panel0.tiles.graphics.annot    = [];

    % ── Right sidebar (scrollable) ────────────────────────────────────────
    mdlObj.Figure.panel1.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 630], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");

    % ── View panel — SRC / VW / CLR via standard selection bus ───────────────
    pan_view.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yView, wInner, hView], ...
        "BackgroundColor", BLACK, ...
        "Title",           "View", ...
        "ForegroundColor", GREEN);
    nex_buildCollectorViewPanel(mdlObj, pan_view.ph, hView);
    bus = mdlObj.collector.View;
    bus.listBoxes.VW.Callback  = @(src,ev) nexFigure_linear_onViewChange(src, ev, 'VW',  mdlObj);
    bus.listBoxes.CLR.Callback = @(src,ev) nexFigure_linear_onViewChange(src, ev, 'CLR', mdlObj);

    % Pre-populate SRC with any result keys already stored on this object
    if isstruct(mdlObj.RESULTS) && ~isempty(fieldnames(mdlObj.RESULTS))
        existingKeys = string(fieldnames(mdlObj.RESULTS))';
        newKeys      = existingKeys(~ismember(existingKeys, bus.selKeys.SRC));
        if ~isempty(newKeys)
            bus.selKeys.SRC          = [bus.selKeys.SRC, newKeys];
            bus.listBoxes.SRC.String = cellstr(bus.selKeys.SRC);
            bus.listBoxes.SRC.Max    = numel(bus.selKeys.SRC);
        end
    end

    % ── Target panel — Y column selector ─────────────────────────────────
    mdlObj.initTargetBus();
    targetOptions = cellstr(mdlObj.collector.Target.options);
    pan_target.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yTarget, wInner, hTarget], ...
        "BackgroundColor", BLACK, ...
        "Title",           "Target (Y)", ...
        "ForegroundColor", GREEN);
    mdlObj.Figure.targetDropdown = uidropdown(pan_target.ph, ...
        "Position",        [5, 5, wInner-10, 25], ...
        "Items",           targetOptions, ...
        "Value",           char(mdlObj.collector.Target.Y), ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ValueChangedFcn", @(src,~) nexFigure_linear_onTargetChange(src, mdlObj));

    % ── Domain panel — D1 / FTR axis selection ───────────────────────────
    pan_domain.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yDomain, wInner, hDomain], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on", ...
        "Title",           "Domain", ...
        "ForegroundColor", GREEN);
    mdlObj.Figure.panel_domain = nexObj_listCfgPanel( ...
        nexon, pan_domain, mdlObj.collector.Domain, [1, numel(axNames)]);
    domainKeys = string(fieldnames(mdlObj.collector.Domain.listBoxes))';
    for i = 1:numel(domainKeys)
        k  = domainKeys(i);
        lb = mdlObj.collector.Domain.listBoxes.(k);
        lb.Callback = @(src,ev) nexFigure_linear_onDomainChange(src, ev, k, mdlObj);
    end

    % ── Pointer panel — per-axis value selector ───────────────────────────
    mdlObj.buildPointerPanel(mdlObj.Figure.panel1.ph, [xInner, yPtr, wInner, hPtr]);

    % ── FitCfg panel ──────────────────────────────────────────────────────
    pan_fitCfg.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFitCfg, wInner, hFitCfg], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_fitCfg = nexObj_cfgPanel_v2( ...
        mdlObj, mdlObj.cfg.fitCfg, pan_fitCfg, ...
        mdlObj.cfg.fitCfg.entryParams, str2func("cfgEntryChanged_v2"), []);

    % ── Fit button ────────────────────────────────────────────────────────
    mdlObj.Figure.fitButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFit, wInner, hBtn], ...
        "Text",            "Fit", ...
        "BackgroundColor", GREEN, ...
        "FontColor",       BLACK, ...
        "FontWeight",      "bold", ...
        "ButtonPushedFcn", @(~,~) mdlObj.fit());
end


% ── Local callbacks ───────────────────────────────────────────────────────

function nexFigure_linear_onTargetChange(src, mdlObj)
    mdlObj.collector.Target.Y = src.Value;
    mdlObj.applyTargetBus();
end

function nexFigure_linear_onDomainChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, char(key), mdlObj.collector.Domain);
    mdlObj.applyDomainBus();
end

function nexFigure_linear_onViewChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, key, mdlObj.collector.View);
    nexFigure_linear_renderSRC(mdlObj);
end
