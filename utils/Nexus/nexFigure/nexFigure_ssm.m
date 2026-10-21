function nexFigure_ssm(mdlObj)
% Interactive figure for mdlObj_ssm. Mirrors nexFigure_pca (the correct
% template -- both unsupervised, no Target/CV panels, which LDA has but
% PCA/SSM don't need):
%   panel0 — eigenspectrum canvas (populated by Eigenspectra button)
%   panel1 — sidebar: Pointer (value windowing) / Pool (pMap: region
%            grouping, block-PCA reduce mode) / Domain (DN·FTR·REG) /
%            View (CTG·SWP·SRC·VW·CLR) / fit cfg / Compile · Fit ·
%            Save·Load · Transform · Eigenspectra · ->StateSpace buttons
%
% Upgraded from the original (Domain + Pool + View + FitCfg + Eigenspectra
% + Save/Load + Fit only) to add: Pointer panel, Transform controls,
% Compile button, and a ->StateSpace pairing button -- same pieces
% nexFigure_pca/_lda/_lme already have. Deliberately NOT added: Target
% panel (SSM is unsupervised, same as PCA -- no Y to pick) and CV panel
% (nexAnalysis_cvPermute's needsHR path isn't wired for non-"supervised"
% dmCfg formats yet -- Nexus WIP.md #5 -- adding Run-CV UI here would
% expose a control that doesn't actually work correctly).

    BLACK = [0 0 0];
    nexon = mdlObj.nexon;
    GREEN = nexon.settings.Colors.cyberGreen;

    % ── Layout constants ──────────────────────────────────────────────────
    xRight  = 665;
    wRight  = 260;
    wInner  = 250;
    xInner  = 5;

    hPtr     = 150;
    hDomain  = 155;
    hFitCfg  = 170;
    hPool    = 165;
    hView    = 175;
    hBtn     = 30;
    gap      = 5;
    hTransLbl = 22;  % nexFigure_addTransformControls draws its label field in this much space above yTrans

    % Bottom-to-top y positions inside the scrollable sidebar -- matches
    % nexFigure_pca's own stacking order exactly, with Eigenspectra/
    % ->StateSpace taking the slots PCA's Visualize/->StateSpace occupy.
    yCompile = xInner;
    yFit     = yCompile + hBtn   + gap;
    ySave    = yFit    + hBtn    + gap;
    yTrans   = ySave   + hBtn    + gap;
    yEig     = yTrans  + hBtn    + hTransLbl + gap;
    yState   = yEig    + hBtn    + gap;
    yFitCfg  = yState  + hBtn    + gap;
    yDomain  = yFitCfg + hFitCfg + gap;
    yPtr     = yDomain + hDomain + gap;
    yPool    = yPtr    + hPtr    + gap;
    yView    = yPool   + hPool   + gap;

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

    dnInit  = find(ismember(axNames, mdlObj.domain.DN));
    if isempty(dnInit), dnInit = 1; end

    ftrInit = find(~ismember(axNames, axNames(dnInit)));
    if isempty(ftrInit), ftrInit = 1; end

    ftrAxes = axNames(ftrInit);
    domainDict.DN  = axNames;
    domainDict.FTR = axNames;
    try
        domainDict.REG = nexOp_computeREGOptions(ftrAxes, mdlObj.Origin.DF_postOp.ax);
    catch
        domainDict.REG = "None";
    end
    mdlObj.domain.REG = "None";
    mdlObj.collector.Domain = buildSelection(mdlObj, domainDict);
    mdlObj.collector.Domain.selections.DN  = dnInit;
    mdlObj.collector.Domain.selections.FTR = ftrInit;
    mdlObj.collector.Domain.selections.REG = 1;

    pan_domain.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yDomain, wInner, hDomain], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on", ...
        "Title",           "Domain", ...
        "ForegroundColor", GREEN);
    mdlObj.Figure.panel_domain = nexObj_listCfgPanel( ...
        nexon, pan_domain, mdlObj.collector.Domain, [numel(axNames), numel(axNames), 1], 10);

    % Reflect the programmatic default selections on the listboxes BEFORE
    % wiring the callback -- same completeness fix nexFigure_pca/_lda
    % already apply (without this, the listbox's own visual highlight can
    % disagree with collector.Domain.selections until the user clicks
    % something themselves).
    domainKeys = string(fieldnames(mdlObj.collector.Domain.listBoxes))';
    for i = 1:numel(domainKeys)
        k   = domainKeys(i);
        lb  = mdlObj.collector.Domain.listBoxes.(k);
        sel = mdlObj.collector.Domain.selections.(k);
        if ~isempty(sel) && all(sel >= 1) && all(sel <= numel(lb.String))
            lb.Value = sel;
        end
        lb.Callback = @(src, ev) nexFigure_ssm_onDomainChange( ...
            src, ev, k, mdlObj);
    end

    %% Pointer panel — per-axis value windowing (single-select = pass-through)
    % Previously missing entirely -- SSM had Domain but no Pointer bus/panel
    % at all. initPointerBus/buildPointerPanel are generic mdlObject base
    % methods (same primitives nexFigure_pca's setupDomain() calls
    % internally), added directly here rather than refactoring SSM's own
    % already-working inline Domain construction above into a setupDomain()
    % wrapper -- surgical addition, not a restructure of working code.
    mdlObj.initPointerBus();
    mdlObj.buildPointerPanel(mdlObj.Figure.panel1.ph, [xInner, yPtr, wInner, hPtr]);

    %% pMap panel — pooling control
    pan_pool.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yPool, wInner, hPool], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_pMap = nexObj_poolCfgPanel_v3( ...
        mdlObj, pan_pool, @poolCfgEntryChanged_v3);

    %% View panel — CTG / SWP / SRC / VW / CLR
    mdlObj.initViewBus();
    pan_view.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yView, wInner, hView], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on", ...
        "Title",           "View", ...
        "ForegroundColor", GREEN);
    % Multi-select, matching nexFigure_lda's own convention -- the
    % listbox allowing multiple SWP values selected is correct/honest now
    % that a real per-combo sweep mechanism for SSM is being built (see
    % WIP.md #18); before that lands, a multi-selection here sits in
    % domain.SWP unread by nexFit_ssm.m, same as it did at cap=1.
    viewMaxSels.SWP = numel(mdlObj.collector.View.selKeys.SWP);
    nex_buildCollectorViewPanel(mdlObj, pan_view.ph, hView, viewMaxSels, 10);
    bus_v = mdlObj.collector.View;
    bus_v.listBoxes.CTG.Callback = @(src,ev) nexFigure_ssm_onViewChange(src, ev, 'CTG', mdlObj);
    bus_v.listBoxes.SWP.Callback = @(src,ev) nexFigure_ssm_onViewChange(src, ev, 'SWP', mdlObj);

    %% Fit cfg panel
    pan_fitCfg.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFitCfg, wInner, hFitCfg], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_fitCfg = nexObj_cfgPanel_v2( ...
        mdlObj, mdlObj.cfg.fitCfg, pan_fitCfg, ...
        mdlObj.cfg.fitCfg.entryParams, str2func("cfgEntryChanged_v2"), []);

    %% Buttons

    % ── ->StateSpace pairing button — launches nexObj_stateSpace on the
    % SSM's own output dfID (mdlObj.dfID_target, auto-derived by the base
    % mdlObject constructor as "ssm_<source>" -- same generic mechanism
    % PCA's own dfID_target relies on, confirmed directly, no SSM-specific
    % setup needed). Requires Fit -> Transform to have already written
    % that dfID, same precondition nexFigure_pca's own button has.
    mdlObj.Figure.stateButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yState, wInner, hBtn], ...
        "Text",            "-> StateSpace", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_ssm_launchStateSpace(mdlObj));

    mdlObj.Figure.eigButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yEig, wInner, hBtn], ...
        "Text",            "Eigenspectra", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_ssm_updateEig(mdlObj));

    % ── Transform controls — previously missing. mdlObj_ssm.transform()
    % is a real, complete implementation (projects emissions into
    % state-space via the fitted SSM) -- same shape as PCA's own
    % transform, so the generic control wires in with zero SSM-specific
    % changes needed.
    [mdlObj.Figure.transformButton, mdlObj.Figure.cbOverwrite, ...
     mdlObj.Figure.cbCurrentTrial] = nexFigure_addTransformControls( ...
        mdlObj.Figure.panel1.ph, mdlObj, [xInner, yTrans, wInner, hBtn], BLACK, GREEN);

    [mdlObj.Figure.saveButton, mdlObj.Figure.loadButton] = ...
        nexFigure_addSaveLoadControls(mdlObj.Figure.panel1.ph, mdlObj, ...
            [xInner, ySave, wInner, hBtn], BLACK, GREEN);

    mdlObj.Figure.fitButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFit, wInner, hBtn], ...
        "Text",            "Fit", ...
        "BackgroundColor", GREEN, ...
        "FontColor",       BLACK, ...
        "FontWeight",      "bold", ...
        "ButtonPushedFcn", @(~,~) mdlObj.fit());

    % ── Compile button — previously missing. Directly relevant to the
    % precompileSTAT/Pointer-bus-seeding work (Nexus WIP.md #16/#17) --
    % lets Pointer options (incl. an epoch-pooled t axis) refresh to the
    % canonical set without a full Fit.
    mdlObj.Figure.compileButton = nexFigure_addCompileControl( ...
        mdlObj.Figure.panel1.ph, mdlObj, [xInner, yCompile, wInner, hBtn], BLACK, GREEN);

end


% ── Local: view bus changed (CTG / SWP) ───────────────────────────────────
function nexFigure_ssm_onViewChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, key, mdlObj.collector.View);
    mdlObj.applyViewBus();
end


% ── Local: domain selection changed ───────────────────────────────────────
function nexFigure_ssm_onDomainChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, char(key), mdlObj.collector.Domain);
    mdlObj.applyDomainBus();
    if key == "FTR"
        mdlObj.refreshREG();
    end
end


% ── Local: launch the paired state-space on the ssm output dfID ──────────
function nexFigure_ssm_launchStateSpace(mdlObj)
% Open a nexObj_stateSpace on the projected output (mdlObj.dfID_target,
% e.g. ssm_RTS_spiking_activity), scoped by the same categorical Parent.
% Requires Fit -> Transform to have already written that dfID into the
% DTS. Direct port of nexFigure_pca's own launchStateSpace -- same
% pairing mechanism, SSM's dfID_target is auto-derived the identical way.
    ctg = mdlObj.Parent;
    if ~isa(ctg, 'nexObj_categorical')
        fprintf(['[nexFigure_ssm] parent is not a categorical — cannot pair a ' ...
                 'stateSpace (launch ssm via nexLaunchAdapt_ssm(ctg)).\n']);
        return;
    end
    if ~isstruct(mdlObj.Partners), mdlObj.Partners = struct(); end
    headline = sprintf("stateSpace - %s", mdlObj.dfID_target);
    mdlObj.Partners.stateSpace = nexObj_stateSpace( ...
        ctg.nexon, ctg, [], mdlObj.dfID_target, headline);
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
    try
        nexObj.applyHeadline();
    catch e
        disp(getReport(e))
    end
end
