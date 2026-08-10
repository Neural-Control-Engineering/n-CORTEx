function nexFigure_pca(mdlObj)
% Interactive figure for mdlObj_pca. Mirrors nexFigure_ssm/_dpca:
%   panel0 — scree / explained-variance canvas (populated by Visualize)
%   panel1 — sidebar: Pointer (value windowing) / Domain (D1·FTR·MSR) /
%            fit cfg / Fit·Transform·Visualize buttons
%
% The Domain bus (incl. the MSR residual-axis value selector) is built via
% mdlObj.setupDomain() — the same entry the headless path uses — so FTR is
% narrowed to a single feature axis and the residual axis (e.g. 'measure')
% defaults to 'rate'.

    BLACK = [0 0 0];
    nexon = mdlObj.nexon;
    GREEN = nexon.settings.Colors.cyberGreen;

    % ── Layout constants ──────────────────────────────────────────────────
    xRight  = 665;
    wRight  = 260;
    wInner  = 250;
    xInner  = 5;

    hPtr     = 150;
    hDomain  = 150;
    hFitCfg  = 145;
    hBtn     = 30;
    gap      = 5;

    % Bottom-to-top y positions inside the scrollable sidebar
    yFit     = xInner;
    yTrans   = yFit    + hBtn    + gap;
    yVis     = yTrans  + hBtn    + gap;
    yState   = yVis    + hBtn    + gap;
    yFitCfg  = yState  + hBtn    + gap;
    yDomain  = yFitCfg + hFitCfg + gap;
    yPtr     = yDomain + hDomain + gap;

    %% Figure
    mdlObj.Figure.fh = uifigure( ...
        "Position", [100, 500, 935, 630], ...
        "Color",    BLACK, ...
        "Name",     sprintf("PCA — %s", mdlObj.dfID_source));

    %% panel0 — scree / explained-variance canvas
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
    xlabel(ax, 'component',             'Color', GREEN);
    ylabel(ax, 'variance explained (%)', 'Color', GREEN);
    title(ax, 'PCA — run Fit, then Visualize', ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);

    %% panel1 — right sidebar (scrollable)
    mdlObj.Figure.panel1.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 620], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");

    %% Pointer panel — per-axis value windowing (single-select = pass-through)
    mdlObj.initPointerBus();
    mdlObj.buildPointerPanel(mdlObj.Figure.panel1.ph, [xInner, yPtr, wInner, hPtr]);

    %% Domain panel — D1 / FTR (axis roles) + MSR (residual-axis value select)
    mdlObj.setupDomain();   % narrows FTR to D2(1), builds collector.Domain (+MSR)

    % Per-key max-selections: D1 single, everything else multi.
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

    % Reflect the programmatic default selections on the listboxes and wire an
    % immediate-apply callback so any change syncs the domain (incl. MSR).
    for i = 1:numel(domKeys)
        k  = domKeys(i);
        lb = mdlObj.collector.Domain.listBoxes.(k);
        sel = mdlObj.collector.Domain.selections.(k);
        if ~isempty(sel) && all(sel >= 1) && all(sel <= numel(lb.String))
            lb.Value = sel;
        end
        lb.Callback = @(src, ev) nexFigure_pca_onDomainChange(src, ev, k, mdlObj);
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
        "ButtonPushedFcn", @(~,~) nexFigure_pca_visualize(mdlObj));

    mdlObj.Figure.transformButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yTrans, wInner, hBtn], ...
        "Text",            "Transform -> DTS", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) mdlObj.scaleApply_transform());

    mdlObj.Figure.stateButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yState, wInner, hBtn], ...
        "Text",            "-> StateSpace", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_pca_launchStateSpace(mdlObj));

    mdlObj.Figure.fitButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFit, wInner, hBtn], ...
        "Text",            "Fit", ...
        "BackgroundColor", GREEN, ...
        "FontColor",       BLACK, ...
        "FontWeight",      "bold", ...
        "ButtonPushedFcn", @(~,~) mdlObj.fit());
end


% ── Local: domain selection changed ───────────────────────────────────────
function nexFigure_pca_onDomainChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, char(key), mdlObj.collector.Domain);
    mdlObj.applyDomainBus();
end


% ── Local: launch the paired state-space on the pca output dfID ────────────
function nexFigure_pca_launchStateSpace(mdlObj)
% Open a nexObj_stateSpace on the projected output (mdlObj.dfID_target,
% e.g. pca_RTS_spk_activity), scoped by the same categorical Parent. Requires
% Fit -> Transform to have already written that dfID into the DTS.
    ctg = mdlObj.Parent;
    if ~isa(ctg, 'nexObj_categorical')
        fprintf(['[nexFigure_pca] parent is not a categorical — cannot pair a ' ...
                 'stateSpace (launch pca via nexLaunchAdapt_pca(ctg)).\n']);
        return;
    end
    if ~isstruct(mdlObj.Partners), mdlObj.Partners = struct(); end
    headline = sprintf("stateSpace - %s", mdlObj.dfID_target);
    mdlObj.Partners.stateSpace = nexObj_stateSpace( ...
        ctg.nexon, ctg, [], mdlObj.dfID_target, headline);
end


% ── Local: scree / explained-variance ─────────────────────────────────────
function nexFigure_pca_visualize(mdlObj)

    BLACK = [0 0 0];
    GREEN = mdlObj.nexon.settings.Colors.cyberGreen;
    ax    = mdlObj.Figure.panel0.tiles.ax;

    if isempty(mdlObj.model)
        fprintf('[nexFigure_pca] model is empty — run Fit first.\n');
        return;
    end

    evr = [];
    try
        evr = double(mdlObj.model.explained_variance_ratio_) * 100;   % percent
    catch e
        fprintf('[nexFigure_pca] no explained_variance_ratio_ — run Fit first.\n');
        disp(getReport(e));
        return;
    end
    evr = evr(:)';

    cla(ax);
    hold(ax, "on");
    bar(ax, 1:numel(evr), evr, 0.7, 'FaceColor', GREEN, 'EdgeColor', BLACK);
    xlabel(ax, 'component',              'Color', GREEN);
    ylabel(ax, 'variance explained (%)', 'Color', GREEN);
    title(ax, sprintf('PCA scree — %s  (%.1f%% in %d PCs)', ...
          mdlObj.dfID_source, sum(evr), numel(evr)), ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9, 'Interpreter', 'none');
end
