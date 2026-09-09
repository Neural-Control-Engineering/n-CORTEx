function nexFigure_lda(mdlObj)
% Interactive figure for mdlObj_lda.
%   panel0 — LD scatter canvas (populated by Visualize)
%   panel1 — sidebar (scrollable): Target / Pool / Pointer / Domain /
%             FitCfg / Visualize / Open Viewer / CV cfg / Result ID /
%             Run CV / Transform / Save·Load / Fit

    BLACK = [0 0 0];
    nexon = mdlObj.nexon;
    GREEN = nexon.settings.Colors.cyberGreen;

    % ── Layout constants ──────────────────────────────────────────────────
    xRight  = 665;
    wRight  = 260;
    wInner  = 250;
    xInner  = 5;

    hBtn     = 30;
    hFitCfg  = 100;
    hDomain  = 150;
    hPtr     = 150;
    hPool    = 165;
    hTarget  = 55;
    hCvCfg   = 80;
    hResultID= 55;
    gap      = 5;

    % Bottom-to-top y positions inside the scrollable sidebar
    yFit      = xInner;
    ySave     = yFit       + hBtn      + gap;
    yTrans    = ySave      + hBtn      + gap;
    yRunCV    = yTrans     + hBtn      + gap;
    yResultID = yRunCV     + hBtn      + gap;
    yCvCfg    = yResultID  + hResultID + gap;
    yViewer   = yCvCfg     + hCvCfg   + gap;
    yVis      = yViewer    + hBtn      + gap;
    yFitCfg   = yVis       + hBtn      + gap;
    yDomain   = yFitCfg    + hFitCfg   + gap;
    yPtr      = yDomain    + hDomain   + gap;
    yPool     = yPtr       + hPtr      + gap;
    yTarget   = yPool      + hPool     + gap;

    % ── Figure ────────────────────────────────────────────────────────────
    mdlObj.Figure.fh = uifigure( ...
        "Position", [100, 500, 935, 630], ...
        "Color",    BLACK, ...
        "Name",     sprintf("LDA — %s", mdlObj.dfID_source));

    % ── Canvas (left panel) — LD scatter ─────────────────────────────────
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
    xlabel(ax, 'LD 1', 'Color', GREEN);
    ylabel(ax, 'LD 2', 'Color', GREEN);
    title(ax, 'LDA — run Fit, then Visualize', ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);

    % ── Right sidebar (scrollable) ────────────────────────────────────────
    mdlObj.Figure.panel1.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 620], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");

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
        "ValueChangedFcn", @(src,~) nexFigure_lda_onTargetChange(src, mdlObj));

    % ── Pool panel ────────────────────────────────────────────────────────
    pan_pool.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yPool, wInner, hPool], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_pMap = nexObj_poolCfgPanel_v3( ...
        mdlObj, pan_pool, @poolCfgEntryChanged_v3);

    % ── Pointer + Domain panels ───────────────────────────────────────────
    mdlObj.setupDomain();   % narrows FTR to D2(1), builds Domain + Pointer buses

    mdlObj.buildPointerPanel(mdlObj.Figure.panel1.ph, [xInner, yPtr, wInner, hPtr]);

    domKeys = string(fieldnames(mdlObj.collector.Domain.selKeys))';
    maxSels = zeros(1, numel(domKeys));
    for i = 1:numel(domKeys)
        k = domKeys(i);
        if k == "D1", maxSels(i) = 1;
        else,         maxSels(i) = numel(mdlObj.collector.Domain.selKeys.(k));
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
        lb.Callback = @(src, ev) nexFigure_lda_onDomainChange(src, ev, k, mdlObj);
    end

    % ── FitCfg panel ─────────────────────────────────────────────────────
    pan_fitCfg.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFitCfg, wInner, hFitCfg], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_fitCfg = nexObj_cfgPanel_v2( ...
        mdlObj, mdlObj.cfg.fitCfg, pan_fitCfg, ...
        mdlObj.cfg.fitCfg.entryParams, str2func("cfgEntryChanged_v2"), []);

    % ── Visualize button ──────────────────────────────────────────────────
    mdlObj.Figure.visButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yVis, wInner, hBtn], ...
        "Text",            "Visualize", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_lda_visualize(mdlObj));

    % ── Open Viewer button ────────────────────────────────────────────────
    mdlObj.Figure.viewerButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yViewer, wInner, hBtn], ...
        "Text",            "Open Results Viewer", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_lda_openViewer(mdlObj));

    % ── CV cfg panel — nFolds / nPermute ──────────────────────────────────
    pan_cv.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yCvCfg, wInner, hCvCfg], ...
        "BackgroundColor", BLACK, ...
        "Title",           "CV", ...
        "ForegroundColor", GREEN);
    wLbl = 80; wFld = wInner - wLbl - 20;
    uilabel(pan_cv.ph, "Position", [5, 40, wLbl, 22], ...
        "Text", "nFolds", "FontColor", GREEN, "BackgroundColor", BLACK);
    mdlObj.Figure.nFoldsField = uieditfield(pan_cv.ph, 'numeric', ...
        "Position",        [wLbl+5, 40, wFld, 22], ...
        "Value",           mdlObj.cfg.cvCfg.entryParams.nFolds, ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ValueChangedFcn", @(src,~) setfield_cvCfg(mdlObj, 'nFolds',   src.Value));
    uilabel(pan_cv.ph, "Position", [5, 12, wLbl, 22], ...
        "Text", "nPermute", "FontColor", GREEN, "BackgroundColor", BLACK);
    mdlObj.Figure.nPermuteField = uieditfield(pan_cv.ph, 'numeric', ...
        "Position",        [wLbl+5, 12, wFld, 22], ...
        "Value",           mdlObj.cfg.cvCfg.entryParams.nPermute, ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ValueChangedFcn", @(src,~) setfield_cvCfg(mdlObj, 'nPermute', src.Value));

    % ── Result ID field ───────────────────────────────────────────────────
    pan_rid.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yResultID, wInner, hResultID], ...
        "BackgroundColor", BLACK, ...
        "Title",           "Result ID", ...
        "ForegroundColor", GREEN);
    mdlObj.Figure.resultIDField = uieditfield(pan_rid.ph, 'text', ...
        "Position",        [5, 5, wInner-15, 25], ...
        "Value",           "cv_1", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN);

    % ── Run CV button ─────────────────────────────────────────────────────
    mdlObj.Figure.cvButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yRunCV, wInner, hBtn], ...
        "Text",            "Run CV", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_lda_runCV(mdlObj));

    % ── Transform controls ────────────────────────────────────────────────
    [mdlObj.Figure.transformButton, mdlObj.Figure.cbOverwrite, ...
     mdlObj.Figure.cbCurrentTrial] = nexFigure_addTransformControls( ...
        mdlObj.Figure.panel1.ph, mdlObj, [xInner, yTrans, wInner, hBtn], BLACK, GREEN);

    % ── Save / Load controls ──────────────────────────────────────────────
    [mdlObj.Figure.saveButton, mdlObj.Figure.loadButton] = ...
        nexFigure_addSaveLoadControls( ...
            mdlObj.Figure.panel1.ph, mdlObj, [xInner, ySave, wInner, hBtn], BLACK, GREEN);

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

function nexFigure_lda_onTargetChange(src, mdlObj)
    mdlObj.collector.Target.Y = src.Value;
    mdlObj.applyTargetBus();
end

function nexFigure_lda_onDomainChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, char(key), mdlObj.collector.Domain);
    mdlObj.applyDomainBus();
end

function nexFigure_lda_runCV(mdlObj)
    resultID = strtrim(mdlObj.Figure.resultIDField.Value);
    if isempty(resultID), resultID = sprintf('cv_%s', char(datetime('now','Format','HHmmss'))); end
    nexAnalysis_cvPermute(mdlObj, resultID);
end

function nexFigure_lda_openViewer(mdlObj)
    if ~isstruct(mdlObj.Partners), mdlObj.Partners = struct(); end
    mdlObj.Partners.viewer = nexObj_resultsViewer(mdlObj);
end

function nexFigure_lda_visualize(mdlObj)
    BLACK = [0 0 0];
    GREEN = mdlObj.nexon.settings.Colors.cyberGreen;
    ax    = mdlObj.Figure.panel0.tiles.ax;

    if isempty(mdlObj.STAT)
        fprintf('[nexFigure_lda] STAT is empty — run Fit first.\n');
        return;
    end

    tVar = char(mdlObj.dfID_target);
    Z_all = []; Y_all = {};
    try
        for r = 1:height(mdlObj.STAT)
            DF_X = table2struct(mdlObj.STAT(r,:));
            DF_Z = mdlObj.transform(DF_X);
            if ~isempty(DF_Z) && ~isempty(DF_Z.df)
                Z_all = [Z_all; DF_Z.df]; %#ok<AGROW>
                label = mdlObj.STAT.(tVar){r};
                if ischar(label) || isstring(label)
                    Y_all(end+1:end+size(DF_Z.df,1)) = {char(label)}; %#ok<AGROW>
                end
            end
        end
    catch e
        fprintf('[nexFigure_lda] transform error — run Fit first.\n');
        disp(getReport(e)); return;
    end

    if isempty(Z_all) || size(Z_all,2) < 1
        fprintf('[nexFigure_lda] no LD components to plot.\n');
        return;
    end

    cla(ax); hold(ax, "on");
    classes = unique(Y_all);
    clrMap  = lines(numel(classes));
    for ci = 1:numel(classes)
        mask = strcmp(Y_all, classes{ci});
        x1 = Z_all(mask, 1);
        x2 = zeros(sum(mask), 1);
        if size(Z_all,2) >= 2, x2 = Z_all(mask, 2); end
        scatter(ax, x1, x2, 15, clrMap(ci,:), 'filled', ...
            'MarkerFaceAlpha', 0.7, 'DisplayName', classes{ci});
    end
    legend(ax, 'Location', 'best', 'TextColor', GREEN, 'Color', BLACK);
    xlabel(ax, 'LD 1', 'Color', GREEN);
    ylabel(ax, 'LD 2', 'Color', GREEN);
    title(ax, sprintf('LDA — %s  (%d pts)', mdlObj.dfID_source, size(Z_all,1)), ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9, 'Interpreter', 'none');
end

function setfield_cvCfg(mdlObj, field, value)
    mdlObj.cfg.cvCfg.entryParams.(field) = value;
end
