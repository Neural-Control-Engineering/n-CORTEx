function nexFigure_dpca(mdlObj)

    BLACK = [0 0 0];
    nexon = mdlObj.nexon;
    GREEN = nexon.settings.Colors.cyberGreen;

    % ── Layout constants ──────────────────────────────────────────────────
    xRight  = 665;
    wRight  = 260;
    wInner  = 250;
    xInner  = 5;

    hCondVars = 200;
    hFitCfg   = 145;
    hPtr      = 150;
    hBtn      = 30;
    gap       = 5;

    yFit      = xInner;
    yVis      = yFit    + hBtn      + gap;
    yFitCfg   = yVis    + hBtn      + gap;
    yPtr      = yFitCfg + hFitCfg   + gap;
    yCondVars = yPtr    + hPtr      + gap;

    %% Figure
    mdlObj.Figure.fh = uifigure( ...
        "Position", [100, 500, 935, 630], ...
        "Color",    BLACK, ...
        "Name",     sprintf("dPCA — %s", mdlObj.dfID_source));

    %% panel0 — main canvas (explained-variance bar chart; populated by Visualize)
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
    xlabel(ax, 'component',         'Color', GREEN);
    ylabel(ax, 'variance explained (%)', 'Color', GREEN);
    title(ax, 'dPCA — run Fit, then Visualize', ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);

    %% panel1 — right sidebar (scrollable)
    mdlObj.Figure.panel1.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 620], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");

    %% Pointer panel — per-axis value selector
    mdlObj.initPointerBus();
    mdlObj.buildPointerPanel(mdlObj.Figure.panel1.ph, [xInner, yPtr, wInner, hPtr]);

    %% CondVars listbox — multi-select task/condition variables
    condCols = nexFigure_dpca_condVarOptions(mdlObj);
    mdlObj.collector.CondVars.Y       = condCols(1);
    mdlObj.collector.CondVars.options = condCols;

    pan_cv = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yCondVars, wInner, hCondVars], ...
        "BackgroundColor", BLACK, ...
        "Title",           "Condition Variables", ...
        "ForegroundColor", GREEN);

    mdlObj.Figure.cvListbox = uilistbox(pan_cv, ...
        "Items",             cellstr(condCols), ...
        "Value",             cellstr(condCols(1)), ...
        "Multiselect",       "on", ...
        "BackgroundColor",   BLACK, ...
        "FontColor",         GREEN, ...
        "Position",          [2, 2, wInner - 4, hCondVars - 22], ...
        "ValueChangedFcn",   @(src, ~) nexFigure_dpca_onCondVarsChanged(src, mdlObj));

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
        "ButtonPushedFcn", @(~,~) nexFigure_dpca_visualize(mdlObj));

    mdlObj.Figure.fitButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFit, wInner, hBtn], ...
        "Text",            "Fit", ...
        "BackgroundColor", GREEN, ...
        "FontColor",       BLACK, ...
        "FontWeight",      "bold", ...
        "ButtonPushedFcn", @(~,~) mdlObj.fit());
end


% ── Local helpers ─────────────────────────────────────────────────────────

function cols = nexFigure_dpca_condVarOptions(mdlObj)
    cols = string.empty;
    try
        S_cat  = nex_returnSelectionMask(mdlObj.Origin.selectionBus.categories);
        catIDs = string(struct2cell(S_cat))';
        catIDs = strrep(catIDs(~strcmp(catIDs, "None")), "--", "_");
        cols   = catIDs;
    catch
    end
    try
        DTS     = mdlObj.nexon.console.BASE.DTS;
        allIDs  = dtsIO_readDFIDs(DTS);
        exclude = ["sessionLabel","trialNumber","h5_path","h5_root"];
        h5IDs   = allIDs(~ismember(allIDs, [cols, exclude]));
        cols    = [cols, h5IDs];
    catch
    end
    if isempty(cols), cols = "sessionLabel_phase"; end
end


function nexFigure_dpca_onCondVarsChanged(src, mdlObj)
    mdlObj.collector.CondVars.Y = string(src.Value);
end


function nexFigure_dpca_visualize(mdlObj)

    BLACK = [0 0 0];
    GREEN = mdlObj.nexon.settings.Colors.cyberGreen;

    if isempty(mdlObj.W)
        fprintf('[nexFigure_dpca] W is empty — run Fit first.\n');
        return;
    end

    W = mdlObj.W;
    whichMarg = W.whichMarg;    % (1 × nComp) marginalization index per component
    margNames = W.margNames;    % cell of labels
    nComp  = numel(whichMarg);
    nMarg  = numel(margNames);

    % Extract per-component explained variance.
    % margVar is already in percent (library divides by totalVar*100 at storage).
    explVarPct = zeros(1, nComp);
    try
        ev = W.explVar;
        if isfield(ev, 'margVar')
            for c = 1:nComp
                m = whichMarg(c);
                if m >= 1 && m <= size(ev.margVar, 1)
                    explVarPct(c) = ev.margVar(m, c);
                end
            end
        elseif isfield(ev, 'componentVar')
            explVarPct = ev.componentVar(:)';
        end
    catch
    end

    % Color palette — one distinct color per marginalization
    cmap = lines(max(nMarg, 1));
    barColors = cmap(max(1, whichMarg), :);  % (nComp × 3)

    % Re-layout canvas — one tile per marginalization
    delete(mdlObj.Figure.panel0.tiles.t);
    nCols = min(nMarg, 3);
    nRows = ceil(nMarg / max(nCols, 1));
    tl = tiledlayout(mdlObj.Figure.panel0.ph, nRows, nCols, ...
        "TileSpacing", "compact", "Padding", "compact");
    mdlObj.Figure.panel0.tiles.t  = tl;
    mdlObj.Figure.panel0.tiles.ax = gobjects(nMarg, 1);

    for m = 1:nMarg
        ax = nexttile(tl);
        mdlObj.Figure.panel0.tiles.ax(m) = ax;
        ax.Color     = BLACK;
        ax.XColor    = GREEN;
        ax.YColor    = GREEN;
        ax.GridColor = GREEN;
        ax.GridAlpha = 0.12;
        ax.Box       = "on";
        ax.FontSize  = 8;
        grid(ax, "on");
        hold(ax, "on");

        comps_m = find(whichMarg == m);
        if ~isempty(comps_m)
            for ci = 1:numel(comps_m)
                c = comps_m(ci);
                bar(ax, c, explVarPct(c), 0.7, ...
                    'FaceColor', barColors(c,:), 'EdgeColor', BLACK);
            end
        end
        title(ax, margNames{m}, 'Color', GREEN, 'FontWeight', 'normal', ...
              'FontSize', 8, 'Interpreter', 'none');
        xlabel(ax, 'component', 'Color', GREEN, 'FontSize', 7);
        ylabel(ax, 'var %',     'Color', GREEN, 'FontSize', 7);
    end

    fprintf('[nexFigure_dpca] visualized %d components across %d marginalizations\n', ...
        nComp, nMarg);
end
