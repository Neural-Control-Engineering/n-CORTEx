function nexFigure_resultsViewer(obj)
% Figure for nexObj_resultsViewer.
%
% Layout (960 × 600):
%   Left  (690px) — atlas-style tabs: Accuracy | Confusion | ROC | Weights
%   Right (255px) — SRC panel  (result selector,  uicontrol listbox)
%                   VW  panel  (fold filter,       uicontrol listbox)
%                   Pointer panel (axis navigation, rebuilt on SRC change)
%
% Uses uifigure (consistent with other nexObject figures).  uicontrol
% listboxes are used for SRC/VW so the inherited refreshSRC / refreshVW_rv
% methods can update .String / .Max / .Value directly.

    BLACK = [0 0 0];
    GREEN = resolveGreen(obj);

    fh = uifigure( ...
        'Position',  [200, 200, 960, 600], ...
        'Color',     BLACK, ...
        'Name',      char(obj.headline));
    obj.Figure.fh = fh;
    obj.applyHeadline();

    wRight = 255;
    xRight = 960 - wRight - 5;

    % ── Right sidebar ──────────────────────────────────────────────────────

    % SRC — result selector (single-select, uicontrol for .String API compat)
    pan_src = uipanel(fh, ...
        'Position',        [xRight, 455, wRight, 140], ...
        'BackgroundColor', BLACK, ...
        'Title',           'Result (SRC)', ...
        'ForegroundColor', GREEN);
    lb_src = uicontrol(pan_src, ...
        'Style',           'listbox', ...
        'String',          {}, ...
        'Max',             1, ...
        'Value',           [], ...
        'Units',           'normalized', ...
        'Position',        [0.02 0.05 0.96 0.90], ...
        'BackgroundColor', BLACK, ...
        'ForegroundColor', GREEN, ...
        'FontSize',        9, ...
        'Callback',        @(lb,~) obj.onSRCChanged(lb));
    obj.collector.View.listBoxes.SRC = lb_src;

    % VW — fold filter (multi-select)
    pan_vw = uipanel(fh, ...
        'Position',        [xRight, 310, wRight, 140], ...
        'BackgroundColor', BLACK, ...
        'Title',           'Folds (VW)', ...
        'ForegroundColor', GREEN);
    lb_vw = uicontrol(pan_vw, ...
        'Style',           'listbox', ...
        'String',          {}, ...
        'Max',             100, ...
        'Value',           [], ...
        'Units',           'normalized', ...
        'Position',        [0.02 0.05 0.96 0.90], ...
        'BackgroundColor', BLACK, ...
        'ForegroundColor', GREEN, ...
        'FontSize',        9, ...
        'Callback',        @(~,~) obj.visualize());
    obj.collector.View.listBoxes.VW = lb_vw;

    % Pointer container — rebuilt by rebuildPointerPanel on SRC change
    pan_ptr = uipanel(fh, ...
        'Position',        [xRight, 5, wRight, 300], ...
        'BackgroundColor', BLACK, ...
        'Title',           'Pointer', ...
        'ForegroundColor', GREEN, ...
        'Scrollable',      'on');
    obj.Figure.ptrContainer = pan_ptr;

    % ── Left: tab nav bar + canvas ─────────────────────────────────────────
    wLeft   = xRight - 10;
    hNav    = 30;
    hCanvas = 590 - hNav - 10;

    uibutton(fh, ...
        'Position',        [5, hCanvas+15, 28, hNav], ...
        'Text',            '<', ...
        'BackgroundColor', BLACK, ...
        'FontColor',       GREEN, ...
        'ButtonPushedFcn', @(~,~) nexFigure_rv_navTab(obj, -1));
    obj.Figure.tabLabel = uilabel(fh, ...
        'Position',        [38, hCanvas+15, wLeft-72, hNav], ...
        'Text',            'Accuracy', ...
        'FontColor',       GREEN, ...
        'BackgroundColor', BLACK, ...
        'HorizontalAlignment', 'center', ...
        'FontSize',        11);
    uibutton(fh, ...
        'Position',        [38+wLeft-72, hCanvas+15, 28, hNav], ...
        'Text',            '>', ...
        'BackgroundColor', BLACK, ...
        'FontColor',       GREEN, ...
        'ButtonPushedFcn', @(~,~) nexFigure_rv_navTab(obj, +1));

    % ── Tab panels ─────────────────────────────────────────────────────────
    tabPos = [5, 5, wLeft, hCanvas];

    % Tab 1 — Accuracy
    pan_acc = uipanel(fh, 'Position', tabPos, 'BackgroundColor', BLACK, 'Visible', 'on');
    ax_acc  = uiaxes(pan_acc, ...
        'Position',  [35, 40, wLeft-60, hCanvas-70], ...
        'Color',     BLACK, ...
        'XColor',    GREEN, ...
        'YColor',    GREEN);
    ax_acc.GridColor = GREEN; ax_acc.GridAlpha = 0.12;
    ax_acc.Box = 'on'; grid(ax_acc, 'on'); hold(ax_acc, 'on');
    xlabel(ax_acc, 'Time',              'Color', GREEN);
    ylabel(ax_acc, 'Balanced accuracy', 'Color', GREEN);

    % Tab 2 — Confusion (stub)
    pan_conf = uipanel(fh, 'Position', tabPos, 'BackgroundColor', BLACK, 'Visible', 'off');
    uilabel(pan_conf, 'Position', [10 10 400 30], ...
        'Text', 'Confusion matrix — not yet implemented', ...
        'FontColor', GREEN, 'BackgroundColor', BLACK);

    % Tab 3 — ROC (stub)
    pan_roc = uipanel(fh, 'Position', tabPos, 'BackgroundColor', BLACK, 'Visible', 'off');
    uilabel(pan_roc, 'Position', [10 10 300 30], ...
        'Text', 'ROC — not yet implemented', ...
        'FontColor', GREEN, 'BackgroundColor', BLACK);

    % Tab 4 — Weights (stub)
    pan_wts = uipanel(fh, 'Position', tabPos, 'BackgroundColor', BLACK, 'Visible', 'off');
    uilabel(pan_wts, 'Position', [10 10 300 30], ...
        'Text', 'Model weights — not yet implemented', ...
        'FontColor', GREEN, 'BackgroundColor', BLACK);

    % ── Tab state ──────────────────────────────────────────────────────────
    obj.Figure.tabNames  = ["Accuracy", "Confusion", "ROC", "Weights"];
    obj.Figure.tabPanels = {pan_acc, pan_conf, pan_roc, pan_wts};
    obj.Figure.tabIdx    = 1;

    % ── Render closures ────────────────────────────────────────────────────
    obj.Figure.renderFcns.active   = "Accuracy";
    obj.Figure.renderFcns.Accuracy = @() nexFigure_rv_renderAccuracy(obj, ax_acc);
end


% ── Helpers ───────────────────────────────────────────────────────────────────

function GREEN = resolveGreen(obj)
    try
        GREEN = obj.nexon.settings.Colors.cyberGreen;
    catch
        GREEN = [0.18 0.8 0.44];
    end
end


% ── Tab navigation ────────────────────────────────────────────────────────────
function nexFigure_rv_navTab(obj, delta)
    n   = numel(obj.Figure.tabNames);
    idx = mod(obj.Figure.tabIdx - 1 + delta, n) + 1;
    obj.Figure.tabPanels{obj.Figure.tabIdx}.Visible = 'off';
    obj.Figure.tabIdx              = idx;
    obj.Figure.tabLabel.Text       = char(obj.Figure.tabNames(idx));
    obj.Figure.tabPanels{idx}.Visible = 'on';
    obj.Figure.renderFcns.active   = obj.Figure.tabNames(idx);
    obj.visualize();
end


% ── Accuracy tab renderer ─────────────────────────────────────────────────────
function nexFigure_rv_renderAccuracy(obj, ax)
% Reads current SRC, VW (fold filter), and Pointer (time window) from obj.
%
% Temporal (R.df: [nFolds × (1+nPermute) × nTime]):
%   mean ± std accuracy curve over time for selected folds.
% Scalar (R.df: [nFolds × (1+nPermute)]):
%   Bar chart, one bar per selected fold.

    BLACK = [0 0 0];
    GREEN = resolveGreen(obj);
    GRAY  = [0.4 0.4 0.4];

    cla(ax); hold(ax, 'on');

    % Current SRC
    bus    = obj.collector.View;
    srcIdx = bus.selections.SRC;
    if isempty(srcIdx) || isempty(bus.selKeys.SRC), return; end
    srcKey = char(bus.selKeys.SRC(min(srcIdx(end), numel(bus.selKeys.SRC))));
    if ~isfield(obj.RESULTS, srcKey), return; end
    R = obj.RESULTS.(srcKey);
    if ~isstruct(R) || ~isfield(R, 'df'), return; end

    % Fold (VW) selection
    vwIdx   = bus.selections.VW;
    nFoldsR = size(R.df, 1);
    if isempty(vwIdx) || isempty(bus.selKeys.VW)
        foldSel = 1:nFoldsR;
    else
        foldSel = sort(vwIdx(vwIdx >= 1 & vwIdx <= nFoldsR));
        if isempty(foldSel), foldSel = 1:nFoldsR; end
    end

    scores = R.df;

    if ndims(scores) >= 3 && size(scores, 3) > 1
        % ── Temporal ─────────────────────────────────────────────────────
        t_ax = R.ax.t;

        % Pointer time-window selection
        if ~isempty(obj.collector.Pointer) && ...
                isfield(obj.collector.Pointer.selections, 't')
            tSel = obj.collector.Pointer.selections.t;
            if numel(tSel) > 1 && numel(tSel) < numel(t_ax)
                t_ax   = t_ax(tSel);
                scores = scores(:, :, tSel);
            end
        end

        real_sc = squeeze(scores(foldSel, 1, :));
        null_sc = scores(foldSel, 2:end, :);

        if size(real_sc, 1) == 1
            mu  = real_sc(:)';
            sig = zeros(size(mu));
        else
            mu  = mean(real_sc, 1);
            sig = std(real_sc, 0, 1);
        end
        null_mu = mean(null_sc(:));
        null_hi = prctile(null_sc(:), 95);

        fill(ax, [t_ax(:)', fliplr(t_ax(:)')], ...
             [mu - sig, fliplr(mu + sig)], GREEN, ...
             'FaceAlpha', 0.15, 'EdgeColor', 'none');
        plot(ax, t_ax, mu, 'Color', GREEN, 'LineWidth', 1.5);
        yline(ax, null_mu, '--', 'Color', GRAY, 'LineWidth', 1);
        yline(ax, null_hi, ':',  'Color', GRAY, 'LineWidth', 1);

        xlabel(ax, 'Time',              'Color', GREEN);
        ylabel(ax, 'Balanced accuracy', 'Color', GREEN);
        nPerm = size(R.df, 2) - 1;
        title(ax, sprintf('%s  folds[%s]  null: mean=%.3f p95=%.3f (%d perm)', ...
              srcKey, num2str(foldSel), null_mu, null_hi, nPerm), ...
              'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 8, ...
              'Interpreter', 'none');

    else
        % ── Scalar ───────────────────────────────────────────────────────
        if ndims(scores) >= 3, scores = scores(:,:,1); end
        sc      = scores(foldSel, :);
        real_sc = sc(:, 1);
        null_sc = sc(:, 2:end);
        null_mu = mean(null_sc(:));
        null_hi = prctile(null_sc(:), 95);

        bar(ax, foldSel, real_sc, 0.6, 'FaceColor', GREEN, 'EdgeColor', BLACK);
        yline(ax, null_mu, '--', 'Color', GRAY, 'LineWidth', 1);
        yline(ax, null_hi, ':',  'Color', GRAY, 'LineWidth', 1);
        xlabel(ax, 'Fold',     'Color', GREEN);
        ylabel(ax, 'Accuracy', 'Color', GREEN);
        title(ax, sprintf('%s  null: mean=%.3f p95=%.3f', srcKey, null_mu, null_hi), ...
              'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 8, 'Interpreter', 'none');
    end
end
