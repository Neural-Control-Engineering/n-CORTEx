function nexFigure_linear(mdlObj)

    BLACK = [0 0 0];
    nexon = mdlObj.nexon;
    GREEN = nexon.settings.Colors.cyberGreen;

    % ── Layout constants ──────────────────────────────────────────────────
    xRight  = 665;
    wRight  = 260;
    wInner  = 250;
    xInner  = 5;

    hSrc     = 55;
    hTarget  = 55;
    hDomain  = 130;
    hFitCfg  = 130;
    hBtn     = 30;
    gap      = 5;

    yFit    = xInner;
    yDomain = yFit    + hBtn    + gap;
    yFitCfg = yDomain + hDomain + gap;
    yTarget = yFitCfg + hFitCfg + gap;
    ySrc    = yTarget + hTarget  + gap;
    hTotal  = ySrc   + hSrc     + gap;

    %% Figure
    mdlObj.Figure.fh = uifigure( ...
        "Position", [100, 500, 935, 630], ...
        "Color",    BLACK, ...
        "Name",     sprintf("Linear — %s", mdlObj.dfID_source));

    %% panel0 — main canvas (scatter or CV results)
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

    mdlObj.Figure.panel0.tiles.graphics.scatter   = [];
    mdlObj.Figure.panel0.tiles.graphics.identity  = [];
    mdlObj.Figure.panel0.tiles.graphics.annot     = [];

    %% panel1 — right sidebar (scrollable)
    mdlObj.Figure.panel1.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 630], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");

    %% SRC dropdown — switch between fit view and RESULTS keys
    pan_src.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, ySrc, wInner, hSrc], ...
        "BackgroundColor", BLACK, ...
        "Title",           "Source", ...
        "ForegroundColor", GREEN);

    mdlObj.Figure.srcDropdown = uidropdown(pan_src.ph, ...
        "Position",        [5, 5, wInner-10, 25], ...
        "Items",           {"fit"}, ...
        "Value",           "fit", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ValueChangedFcn", @(src,~) nexFigure_linear_onSRCChange(src, mdlObj));

    %% Target bus — which DTS column is Y
    pan_target.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yTarget, wInner, hTarget], ...
        "BackgroundColor", BLACK, ...
        "Title",           "Target (Y)", ...
        "ForegroundColor", GREEN);

    % Seed options from Origin's categories bus; fall back to default
    mdlObj.initTargetBus();
    targetOptions = cellstr(mdlObj.collector.Target.options);

    mdlObj.Figure.targetDropdown = uidropdown(pan_target.ph, ...
        "Position",        [5, 5, wInner-10, 25], ...
        "Items",           targetOptions, ...
        "Value",           char(mdlObj.collector.Target.Y), ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ValueChangedFcn", @(src,~) nexFigure_linear_onTargetChange(src, mdlObj));

    %% Domain selection bus — D1 (time axis) / FTR (feature axis)
    try
        axNames = string(fieldnames(mdlObj.Origin.DF_postOp.ax))';
    catch
        axNames = ["t"];
    end

    d1Init  = find(axNames == mdlObj.domain.D1, 1);
    if isempty(d1Init), d1Init = 1; end
    ftrInit = find(axNames ~= axNames(d1Init));
    if isempty(ftrInit), ftrInit = 1; end

    domainDict.D1  = axNames;
    domainDict.FTR = axNames;
    mdlObj.collector.Domain = buildSelection(mdlObj, domainDict);
    mdlObj.collector.Domain.selections.D1  = d1Init;
    mdlObj.collector.Domain.selections.FTR = ftrInit;

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
        lb.Callback = @(src, ev) nexFigure_linear_onDomainChange(src, ev, k, mdlObj);
    end

    %% Fit cfg panel
    pan_fitCfg.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFitCfg, wInner, hFitCfg], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_fitCfg = nexObj_cfgPanel_v2( ...
        mdlObj, mdlObj.cfg.fitCfg, pan_fitCfg, ...
        mdlObj.cfg.fitCfg.entryParams, str2func("cfgEntryChanged_v2"), []);

    %% Fit button
    mdlObj.Figure.fitButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFit, wInner, hBtn], ...
        "Text",            "Fit", ...
        "BackgroundColor", GREEN, ...
        "FontColor",       BLACK, ...
        "FontWeight",      "bold", ...
        "ButtonPushedFcn", @(~,~) mdlObj.fit());
end


% ── Local callbacks ───────────────────────────────────────────────────────

function nexFigure_linear_onSRCChange(src, mdlObj)
    nexFigure_linear_renderSRC(mdlObj, src.Value);
end

function nexFigure_linear_onTargetChange(src, mdlObj)
    mdlObj.collector.Target.Y = src.Value;
    mdlObj.applyTargetBus();
end

function nexFigure_linear_onDomainChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, char(key), mdlObj.collector.Domain);
    mdlObj.applyDomainBus();
end
