function nexFigure_umap(mdlObj)
% Interactive figure for mdlObj_umap. Layout mirrors nexFigure_pca:
%   panel0 — UMAP embedding scatter canvas (populated by Visualize)
%   panel1 — sidebar: Pointer / Domain (D1·FTR·MSR) / fit cfg /
%             Fit · Transform·DTS · Visualize · ->StateSpace buttons

    BLACK = [0 0 0];
    nexon = mdlObj.nexon;
    GREEN = nexon.settings.Colors.cyberGreen;

    % ── Layout constants ──────────────────────────────────────────────────
    xRight  = 665;
    wRight  = 260;
    wInner  = 250;
    xInner  = 5;

    hPtr     = 150;
    hDomain  = 180;
    hFitCfg  = 175;
    hPool    = 165;
    hBtn     = 30;
    gap      = 5;

    yFit    = xInner;
    ySave   = yFit    + hBtn    + gap;
    yTrans  = ySave   + hBtn    + gap;
    yVis    = yTrans  + hBtn    + gap;
    yState  = yVis    + hBtn    + gap;
    yFitCfg = yState  + hBtn    + gap;
    yDomain = yFitCfg + hFitCfg + gap;
    yPtr    = yDomain + hDomain + gap;
    yPool   = yPtr    + hPtr    + gap;

    %% Figure
    mdlObj.Figure.fh = uifigure( ...
        "Position", [100, 500, 935, 630], ...
        "Color",    BLACK, ...
        "Name",     sprintf("UMAP — %s", mdlObj.dfID_source));

    %% panel0 — embedding scatter canvas
    mdlObj.Figure.panel0.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [5, 5, 655, 620], ...
        "BackgroundColor", BLACK);

    mdlObj.Figure.panel0.tiles.t = tiledlayout(mdlObj.Figure.panel0.ph, 1, 1, ...
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
    xlabel(ax, 'UMAP 1',  'Color', GREEN);
    ylabel(ax, 'UMAP 2',  'Color', GREEN);
    title(ax, 'UMAP — run Fit, then Visualize', ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);

    %% panel1 — right sidebar (scrollable)
    mdlObj.Figure.panel1.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 620], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");

    %% Pointer panel
    mdlObj.initPointerBus();
    mdlObj.buildPointerPanel(mdlObj.Figure.panel1.ph, [xInner, yPtr, wInner, hPtr]);

    %% Pool panel
    pan_pool.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yPool, wInner, hPool], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_pMap = nexObj_poolCfgPanel_v3( ...
        mdlObj, pan_pool, @poolCfgEntryChanged_v3);

    %% Domain panel
    mdlObj.setupDomain();

    domKeys = string(fieldnames(mdlObj.collector.Domain.selKeys))';
    maxSels = zeros(1, numel(domKeys));
    for i = 1:numel(domKeys)
        k = domKeys(i);
        if k == "D1"
            maxSels(i) = 1;
        else
            maxSels(i) = numel(mdlObj.collector.Domain.selKeys.(k));
        end
    end

    pan_domain.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yDomain, wInner, hDomain], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on", ...
        "Title",           "Domain", ...
        "ForegroundColor", GREEN);
    mdlObj.Figure.panel_domain = nexObj_listCfgPanel( ...
        nexon, pan_domain, mdlObj.collector.Domain, maxSels);

    for i = 1:numel(domKeys)
        k  = domKeys(i);
        lb = mdlObj.collector.Domain.listBoxes.(k);
        sel = mdlObj.collector.Domain.selections.(k);
        if ~isempty(sel) && all(sel >= 1) && all(sel <= numel(lb.String))
            lb.Value = sel;
        end
        lb.Callback = @(src, ev) nexFigure_umap_onDomainChange(src, ev, k, mdlObj);
    end

    %% Fit cfg panel
    pan_fitCfg.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFitCfg, wInner, hFitCfg], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_fitCfg = nexObj_cfgPanel_v2( ...
        mdlObj, mdlObj.cfg.fitCfg, pan_fitCfg, ...
        mdlObj.cfg.fitCfg.entryParams, str2func("cfgEntryChanged_v2"), []);

    %% Buttons
    mdlObj.Figure.visButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yVis, wInner, hBtn], ...
        "Text",            "Visualize", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_umap_visualize(mdlObj));

    [mdlObj.Figure.transformButton, mdlObj.Figure.cbOverwrite, mdlObj.Figure.cbCurrentTrial] = ...
        nexFigure_addTransformControls(mdlObj.Figure.panel1.ph, mdlObj, ...
            [xInner, yTrans, wInner, hBtn], BLACK, GREEN);

    [mdlObj.Figure.saveButton, mdlObj.Figure.loadButton] = ...
        nexFigure_addSaveLoadControls(mdlObj.Figure.panel1.ph, mdlObj, ...
            [xInner, ySave, wInner, hBtn], BLACK, GREEN);

    mdlObj.Figure.stateButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yState, wInner, hBtn], ...
        "Text",            "-> StateSpace", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_umap_launchStateSpace(mdlObj));

    mdlObj.Figure.fitButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFit, wInner, hBtn], ...
        "Text",            "Fit", ...
        "BackgroundColor", GREEN, ...
        "FontColor",       BLACK, ...
        "FontWeight",      "bold", ...
        "ButtonPushedFcn", @(~,~) mdlObj.fit());
end


% ── Local: domain selection changed ───────────────────────────────────────
function nexFigure_umap_onDomainChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, char(key), mdlObj.collector.Domain);
    mdlObj.applyDomainBus();
end


% ── Local: launch paired state-space on the UMAP output dfID ──────────────
function nexFigure_umap_launchStateSpace(mdlObj)
    ctg = mdlObj.Parent;
    if ~isa(ctg, 'nexObj_categorical')
        fprintf(['[nexFigure_umap] parent is not categorical — cannot pair a ' ...
                 'stateSpace (launch via nexLaunchAdapt_umap(ctg)).\n']);
        return;
    end
    if ~isstruct(mdlObj.Partners), mdlObj.Partners = struct(); end
    headline = sprintf("stateSpace - %s", mdlObj.dfID_target);
    mdlObj.Partners.stateSpace = nexObj_stateSpace( ...
        ctg.nexon, ctg, [], mdlObj.dfID_target, headline);
end


% ── Local: scatter the UMAP embedding (factors 1 & 2) ─────────────────────
function nexFigure_umap_visualize(mdlObj)

    BLACK = [0 0 0];
    GREEN = mdlObj.nexon.settings.Colors.cyberGreen;
    ax    = mdlObj.Figure.panel0.tiles.ax;

    if isempty(mdlObj.STAT)
        fprintf('[nexFigure_umap] STAT is empty — run Fit first.\n');
        return;
    end

    % Collect transformed embeddings from STAT rows
    DM_all = [];
    try
        for r = 1:height(mdlObj.STAT)
            DF_X = table2struct(mdlObj.STAT(r, :));
            DF_Z = mdlObj.transform(DF_X);
            if ~isempty(DF_Z) && ~isempty(DF_Z.df)
                DM_all = [DM_all; DF_Z.df]; %#ok<AGROW>
            end
        end
    catch e
        fprintf('[nexFigure_umap] transform error — run Fit first.\n');
        disp(getReport(e));
        return;
    end

    if isempty(DM_all) || size(DM_all, 2) < 2
        fprintf('[nexFigure_umap] embedding has fewer than 2 components.\n');
        return;
    end

    cla(ax);
    hold(ax, "on");
    nPts = size(DM_all, 1);
    clr  = parula(nPts);
    scatter(ax, DM_all(:,1), DM_all(:,2), 10, clr, 'filled', 'MarkerFaceAlpha', 0.7);
    xlabel(ax, 'UMAP 1', 'Color', GREEN);
    ylabel(ax, 'UMAP 2', 'Color', GREEN);
    title(ax, sprintf('UMAP — %s  (%d pts, %d dims)', ...
          mdlObj.dfID_source, nPts, size(DM_all, 2)), ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9, 'Interpreter', 'none');
end
