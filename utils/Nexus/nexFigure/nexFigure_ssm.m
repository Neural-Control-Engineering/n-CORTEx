function nexFigure_ssm(mdlObj)

    BLACK = [0 0 0];
    nexon = mdlObj.nexon;
    GREEN = nexon.settings.Colors.cyberGreen;

    % ── Layout constants ──────────────────────────────────────────────────
    xRight  = 665;
    wRight  = 260;
    wInner  = 250;
    xInner  = 5;

    hDomain  = 130;
    hPool    = 165;
    hFitCfg  = 170;
    hBtn     = 30;
    gap      = 5;

    % Bottom-to-top y positions inside the scrollable sidebar
    yFit     = xInner;
    yEig     = yFit    + hBtn    + gap;
    yDomain  = yEig    + hBtn    + gap;
    yFitCfg  = yDomain + hDomain + gap;
    yPool    = yFitCfg + hFitCfg + gap;
    hTotal   = yPool   + hPool   + gap;

    %% Figure
    mdlObj.Figure.fh = uifigure( ...
        "Position", [100, 500, 935, 630], ...
        "Color",    BLACK, ...
        "Name",     sprintf("SSM — %s", mdlObj.dfID_source));

    %% panel0 — Eigenspectra (main canvas)
    mdlObj.Figure.panel0.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [5, 5, 655, 620], ...
        "BackgroundColor", BLACK);

    mdlObj.Figure.panel0.tiles.t = tiledlayout( ...
        mdlObj.Figure.panel0.ph, 1, 1, ...
        "TileSpacing", "compact", "Padding", "compact");
    ax = nexttile(mdlObj.Figure.panel0.tiles.t);
    mdlObj.Figure.panel0.tiles.ax = ax;

    ax.Color      = BLACK;
    ax.XColor     = GREEN;
    ax.YColor     = GREEN;
    ax.GridColor  = GREEN;
    ax.GridAlpha  = 0.12;
    ax.Box        = "on";
    ax.FontSize   = 9;
    grid(ax, "on");
    hold(ax, "on");
    axis(ax, "equal");

    theta_uc = linspace(0, 2*pi, 360);
    plot(ax, cos(theta_uc), sin(theta_uc), '--', ...
         'Color', [GREEN 0.30], 'LineWidth', 0.8, 'HandleVisibility', 'off');
    xline(ax, 0, 'Color', [GREEN 0.20], 'LineWidth', 0.5, 'HandleVisibility', 'off');
    yline(ax, 0, 'Color', [GREEN 0.20], 'LineWidth', 0.5, 'HandleVisibility', 'off');

    xlabel(ax, 'Re(\lambda)', 'Color', GREEN);
    ylabel(ax, 'Im(\lambda)', 'Color', GREEN);
    title(ax, 'Eigenspectrum of A  (dashed = stability boundary)', ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);

    mdlObj.Figure.panel0.tiles.graphics.eigScatter = [];

    %% panel1 — right sidebar (scrollable)
    mdlObj.Figure.panel1.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 620], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");

    %% Domain selection bus — D1 (single) / FTR (multi)
    % Axis names come from Origin.DF_postOp so the bus reflects the live
    % feature space, not a subset filtered by pMap coverage.
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

    % Overwrite listbox callbacks so any selection change immediately
    % applies the domain bus — no button press required.
    domainKeys = string(fieldnames(mdlObj.collector.Domain.listBoxes))';
    for i = 1:numel(domainKeys)
        k  = domainKeys(i);
        lb = mdlObj.collector.Domain.listBoxes.(k);
        lb.Callback = @(src, ev) nexFigure_ssm_onDomainChange( ...
            src, ev, k, mdlObj);
    end

    %% pMap panel — pooling control
    pan_pool.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yPool, wInner, hPool], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_pMap = nexObj_poolCfgPanel_v2( ...
        mdlObj, pan_pool, str2func("poolCfgEntryChanged"));

    %% Fit cfg panel
    pan_fitCfg.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFitCfg, wInner, hFitCfg], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_fitCfg = nexObj_cfgPanel_v2( ...
        mdlObj, mdlObj.cfg.fitCfg, pan_fitCfg, ...
        mdlObj.cfg.fitCfg.entryParams, str2func("cfgEntryChanged_v2"), []);

    %% Buttons
    mdlObj.Figure.eigButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yEig, wInner, hBtn], ...
        "Text",            "Eigenspectra", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_ssm_updateEig(mdlObj));

    mdlObj.Figure.fitButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFit, wInner, hBtn], ...
        "Text",            "Fit", ...
        "BackgroundColor", GREEN, ...
        "FontColor",       BLACK, ...
        "FontWeight",      "bold", ...
        "ButtonPushedFcn", @(~,~) mdlObj.fit());

end


% ── Local: domain selection changed ───────────────────────────────────────
function nexFigure_ssm_onDomainChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, char(key), mdlObj.collector.Domain);
    mdlObj.applyDomainBus();
end


% ── Local: compute and render eigenspectrum ───────────────────────────────
function nexFigure_ssm_updateEig(mdlObj)

    BLACK = [0 0 0];

    if isempty(mdlObj.W)
        disp('[nexFigure_ssm] mdlObj.W is empty — run Fit first.');
        return;
    end

    np = py.importlib.import_module('numpy');
    A  = double(np.asarray(mdlObj.W.params.dynamics.weights));
    ev = eig(A);

    ax    = mdlObj.Figure.panel0.tiles.ax;
    GREEN = mdlObj.nexon.settings.Colors.cyberGreen;

    g = mdlObj.Figure.panel0.tiles.graphics.eigScatter;
    if ~isempty(g) && isvalid(g)
        delete(g);
    end

    sc = scatter(ax, real(ev), imag(ev), 60, GREEN, 'filled', ...
                 'MarkerEdgeColor', BLACK, 'LineWidth', 0.8);
    mdlObj.Figure.panel0.tiles.graphics.eigScatter = sc;

    maxVal = max([abs(real(ev)); abs(imag(ev)); 1.05]) * 1.10;
    xlim(ax, [-maxVal  maxVal]);
    ylim(ax, [-maxVal  maxVal]);

end
