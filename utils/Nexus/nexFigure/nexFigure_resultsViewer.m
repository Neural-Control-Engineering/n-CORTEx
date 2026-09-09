function nexFigure_resultsViewer(obj)
% Figure for nexObj_resultsViewer.
% Layout:
%   Left  (680px) — atlas-style simulated tabs (Accuracy / Confusion / ROC / Weights)
%   Right (250px) — SRC multi-select listbox + Render button
%
% Tab panels stack at the same position; ← → buttons + tab label toggle Visible.
% Tabs are data-driven: only "Accuracy" is implemented; others are stubs.

    BLACK = [0 0 0];
    WHITE = [1 1 1];
    if ~isempty(obj.nexon) && isfield(obj.nexon, 'settings')
        GREEN = obj.nexon.settings.Colors.cyberGreen;
    else
        GREEN = [0.18 0.8 0.44];
    end

    fh = uifigure( ...
        "Position", [200, 300, 960, 600], ...
        "Color",    BLACK, ...
        "Name",     "Results Viewer");
    obj.Figure.fh = fh;

    % ── Right panel — SRC selector ────────────────────────────────────────
    wRight  = 240;
    xRight  = 960 - wRight - 5;
    pan_src = uipanel(fh, ...
        "Position",        [xRight, 5, wRight, 590], ...
        "BackgroundColor", BLACK, ...
        "Title",           "Results", ...
        "ForegroundColor", GREEN);

    obj.Figure.srcListBox = uicontrol(pan_src, ...
        "Style",           "listbox", ...
        "String",          {}, ...
        "Max",             100, ...
        "Value",           [], ...
        "Position",        [5, 40, wRight-15, 520], ...
        "BackgroundColor", BLACK, ...
        "ForegroundColor", GREEN, ...
        "FontSize",        10);

    uicontrol(pan_src, ...
        "Style",           "pushbutton", ...
        "String",          "Render", ...
        "Position",        [5, 5, wRight-15, 28], ...
        "BackgroundColor", BLACK, ...
        "ForegroundColor", GREEN, ...
        "Callback",        @(~,~) obj.render());

    % ── Left area — tab canvas + nav bar ─────────────────────────────────
    wLeft  = xRight - 10;
    hNav   = 30;
    hCanvas= 590 - hNav - 5;

    % Nav bar: ← [Tab Label] →
    obj.Figure.btnPrev = uibutton(fh, ...
        "Position",        [5, hCanvas+10, 30, hNav], ...
        "Text",            "<", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_rv_navTab(obj, -1));
    obj.Figure.tabLabel = uilabel(fh, ...
        "Position",        [40, hCanvas+10, wLeft-75, hNav], ...
        "Text",            "Accuracy", ...
        "FontColor",       GREEN, ...
        "BackgroundColor", BLACK, ...
        "HorizontalAlignment", "center", ...
        "FontSize",        12);
    obj.Figure.btnNext = uibutton(fh, ...
        "Position",        [40+wLeft-75, hCanvas+10, 30, hNav], ...
        "Text",            ">", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_rv_navTab(obj, +1));

    % ── Tab panels — same position, toggled by Visible ────────────────────
    tabPos = [5, 5, wLeft, hCanvas];

    % Tab 1 — Accuracy
    pan_acc = uipanel(fh, ...
        "Position",        tabPos, ...
        "BackgroundColor", BLACK, ...
        "Visible",         "on");
    ax_acc = uiaxes(pan_acc, ...
        "Position",        [30, 30, wLeft-50, hCanvas-60], ...
        "Color",           BLACK, ...
        "XColor",          GREEN, ...
        "YColor",          GREEN);
    ax_acc.GridColor = GREEN; ax_acc.GridAlpha = 0.12;
    ax_acc.Box = "on"; grid(ax_acc, "on"); hold(ax_acc, "on");
    xlabel(ax_acc, 'Result',   'Color', GREEN);
    ylabel(ax_acc, 'Accuracy', 'Color', GREEN);
    title(ax_acc, 'Balanced accuracy — select results and click Render', ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);

    % Tab 2 — Confusion (stub)
    pan_conf = uipanel(fh, ...
        "Position",        tabPos, ...
        "BackgroundColor", BLACK, ...
        "Visible",         "off");
    uilabel(pan_conf, "Position", [10,10,300,30], ...
        "Text", "Confusion matrix — not yet implemented", ...
        "FontColor", GREEN, "BackgroundColor", BLACK);

    % Tab 3 — ROC (stub)
    pan_roc = uipanel(fh, ...
        "Position",        tabPos, ...
        "BackgroundColor", BLACK, ...
        "Visible",         "off");
    uilabel(pan_roc, "Position", [10,10,300,30], ...
        "Text", "ROC — not yet implemented", ...
        "FontColor", GREEN, "BackgroundColor", BLACK);

    % Tab 4 — Weights (stub)
    pan_wts = uipanel(fh, ...
        "Position",        tabPos, ...
        "BackgroundColor", BLACK, ...
        "Visible",         "off");
    uilabel(pan_wts, "Position", [10,10,300,30], ...
        "Text", "Model weights — not yet implemented", ...
        "FontColor", GREEN, "BackgroundColor", BLACK);

    % ── Wire tab navigation state ─────────────────────────────────────────
    tabNames   = ["Accuracy", "Confusion", "ROC", "Weights"];
    tabPanels  = {pan_acc, pan_conf, pan_roc, pan_wts};
    obj.Figure.tabNames  = tabNames;
    obj.Figure.tabPanels = tabPanels;
    obj.Figure.tabIdx    = 1;

    % ── Register render closures ──────────────────────────────────────────
    obj.Figure.renderFcns.active   = "Accuracy";
    obj.Figure.renderFcns.Accuracy = @(selKeys) nexFigure_rv_renderAccuracy(obj, ax_acc, selKeys);

    % Populate listbox with any results already in obj.results
    if isstruct(obj.results) && ~isempty(fieldnames(obj.results))
        ids = string(fieldnames(obj.results))';
        obj.collector.srcKeys = ids;
        obj.Figure.srcListBox.String = cellstr(ids);
        obj.Figure.srcListBox.Max    = numel(ids);
    end
end


% ── Tab navigation ────────────────────────────────────────────────────────
function nexFigure_rv_navTab(obj, delta)
    n   = numel(obj.Figure.tabNames);
    idx = mod(obj.Figure.tabIdx - 1 + delta, n) + 1;
    obj.Figure.tabPanels{obj.Figure.tabIdx}.Visible = "off";
    obj.Figure.tabIdx   = idx;
    obj.Figure.tabLabel.Text = obj.Figure.tabNames(idx);
    obj.Figure.tabPanels{idx}.Visible = "on";
    obj.Figure.renderFcns.active = obj.Figure.tabNames(idx);
end


% ── Accuracy tab renderer ─────────────────────────────────────────────────
function nexFigure_rv_renderAccuracy(obj, ax, selKeys)
% selKeys: string array of selected result IDs.
% 1 key  → fold-by-fold bars (real vs null distribution).
% N keys → comparison: one bar-group per key (mean real ± null band).

    BLACK = [0 0 0];
    if ~isempty(obj.nexon) && isfield(obj.nexon, 'settings')
        GREEN = obj.nexon.settings.Colors.cyberGreen;
    else
        GREEN = [0.18 0.8 0.44];
    end
    GRAY  = [0.4 0.4 0.4];

    cla(ax); hold(ax, 'on');

    if isempty(selKeys)
        return;
    end

    if numel(selKeys) == 1
        % ── Single result: fold-by-fold bars ─────────────────────────────
        R = obj.results.(selKeys(1));
        if ~isfield(R, 'df'), return; end
        scores = R.df;   % [nFolds × (1+nPermute)]
        if ndims(scores) == 3, scores = scores(:,:,1); end
        nFolds = size(scores, 1);
        real_scores = scores(:, 1);
        null_scores = scores(:, 2:end);
        null_mu  = mean(null_scores(:));
        null_hi  = prctile(null_scores(:), 95);

        bar(ax, 1:nFolds, real_scores, 0.6, 'FaceColor', GREEN, 'EdgeColor', BLACK);
        yline(ax, null_mu, '--', 'Color', GRAY, 'LineWidth', 1);
        yline(ax, null_hi, ':',  'Color', GRAY, 'LineWidth', 1);
        xlabel(ax, 'Fold',     'Color', GREEN);
        ylabel(ax, 'Accuracy', 'Color', GREEN);
        title(ax, sprintf('%s — fold accuracy  (null: mean=%.3f, p95=%.3f)', ...
              selKeys(1), null_mu, null_hi), ...
              'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9, 'Interpreter', 'none');
    else
        % ── Multiple results: one bar per result, null band overlaid ──────
        means   = zeros(1, numel(selKeys));
        sems    = zeros(1, numel(selKeys));
        null_hi = zeros(1, numel(selKeys));
        for ki = 1:numel(selKeys)
            id = selKeys(ki);
            if ~isfield(obj.results, id), continue; end
            R = obj.results.(id);
            if ~isfield(R, 'df'), continue; end
            sc = R.df; if ndims(sc) == 3, sc = sc(:,:,1); end
            means(ki)   = mean(sc(:,1));
            sems(ki)    = std(sc(:,1)) / sqrt(size(sc,1));
            null_hi(ki) = prctile(sc(:, 2:end), 95, 'all');
        end
        bar(ax, 1:numel(selKeys), means, 0.6, 'FaceColor', GREEN, 'EdgeColor', BLACK);
        errorbar(ax, 1:numel(selKeys), means, sems, 'Color', WHITE, ...
                 'LineStyle', 'none', 'LineWidth', 1.2);
        scatter(ax, 1:numel(selKeys), null_hi, 30, GRAY, '^', 'filled');
        ax.XTick      = 1:numel(selKeys);
        ax.XTickLabel = cellstr(selKeys);
        ax.XTickLabelRotation = 30;
        xlabel(ax, 'Result',   'Color', GREEN);
        ylabel(ax, 'Accuracy', 'Color', GREEN);
        title(ax, sprintf('Accuracy comparison (%d results)', numel(selKeys)), ...
              'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);
    end
end
