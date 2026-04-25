function nexFigure_linear_renderSRC(mdlObj, srcKey)
% Render the main canvas for mdlObj_linear.
%
%   srcKey = "fit"         → scatter of Y_pred vs Y_actual from last fit
%   srcKey = <resultID>    → box/strip plot of CV fold scores vs null

    if nargin < 2
        if isfield(mdlObj.Figure, 'srcDropdown') && isvalid(mdlObj.Figure.srcDropdown)
            srcKey = mdlObj.Figure.srcDropdown.Value;
        else
            srcKey = "fit";
        end
    end

    ax    = mdlObj.Figure.panel0.tiles.ax;
    BLACK = [0 0 0];
    GREEN = mdlObj.nexon.settings.Colors.cyberGreen;

    cla(ax);
    hold(ax, "on");

    switch srcKey
        case "fit"
            nexFigure_linear_renderFit(mdlObj, ax, GREEN, BLACK);
        otherwise
            if isfield(mdlObj.RESULTS, srcKey)
                nexFigure_linear_renderResults(mdlObj, ax, srcKey, GREEN, BLACK);
            end
    end
end


% ── Scatter: Y_pred vs Y_actual from most recent fit ─────────────────────
function nexFigure_linear_renderFit(mdlObj, ax, GREEN, BLACK)

    if isempty(mdlObj.TEST) || ~isfield(mdlObj.TEST, 'STAT') || ...
            isempty(mdlObj.TEST.STAT)
        title(ax, 'No fit yet — press Fit', ...
              'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);
        xlabel(ax, 'Y actual',    'Color', GREEN);
        ylabel(ax, 'Y predicted', 'Color', GREEN);
        return;
    end

    STAT_test = mdlObj.TEST.STAT;
    tVar = char(mdlObj.dfID_target);

    if ~ismember(tVar, STAT_test.Properties.VariableNames) || ...
            ~ismember('prediction', STAT_test.Properties.VariableNames)
        title(ax, 'Run Fit to populate', ...
              'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);
        return;
    end

    Y_true = STAT_test.(tVar);
    if iscell(Y_true), Y_true = cell2mat(Y_true); end
    Y_true = double(Y_true(:));

    preds = STAT_test.prediction;
    Y_pred = cellfun(@(DF) mean(DF.df(:)), preds);
    Y_pred = Y_pred(:);

    scatter(ax, Y_true, Y_pred, 30, GREEN, 'filled', ...
            'MarkerFaceAlpha', 0.6);

    lo = min([Y_true; Y_pred]);
    hi = max([Y_true; Y_pred]);
    pad = (hi - lo) * 0.05;
    plot(ax, [lo-pad, hi+pad], [lo-pad, hi+pad], '--', ...
         'Color', [GREEN 0.4], 'LineWidth', 0.8);
    xlim(ax, [lo-pad, hi+pad]);
    ylim(ax, [lo-pad, hi+pad]);

    cc = corrcoef(Y_true, Y_pred);
    R2 = cc(1,2)^2;
    text(ax, lo + pad, hi - pad, sprintf('R^2 = %.3f', R2), ...
         'Color', GREEN, 'FontSize', 10, 'VerticalAlignment', 'top');

    xlabel(ax, 'Y actual',    'Color', GREEN);
    ylabel(ax, 'Y predicted', 'Color', GREEN);
    title(ax, sprintf('Predicted vs Actual  —  %s', char(mdlObj.dfID_target)),...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);
end


% ── Strip + box: CV fold scores (real col 1 vs null cols 2:end) ───────────
function nexFigure_linear_renderResults(mdlObj, ax, srcKey, GREEN, BLACK)

    R      = mdlObj.RESULTS.(srcKey);
    scores = double(R.df);  % [nFolds × (1+nPermute)] or [nFolds × (1+nPermute) × nOuter]

    % Detect outer axis (anything in R.ax beyond fold/permute) for title annotation
    outerID = '';
    if isstruct(R.ax)
        axFields    = string(fieldnames(R.ax))';
        outerFields = axFields(~ismember(axFields, ["fold","permute"]));
        if ~isempty(outerFields), outerID = char(outerFields(1)); end
    end

    % Aggregate real scores and null across all folds and outer slices
    allReal = scores(:, 1, :);
    allNull = scores(:, 2:end, :);
    allReal = allReal(:);
    allNull = allNull(:);

    nFolds = size(scores, 1);

    % Null distribution as semi-transparent histogram
    edges = linspace(min([nullFlat; allReal]), max([nullFlat; allReal]), 40);
    histogram(ax, nullFlat, edges, ...
              'FaceColor', GREEN*0.4, 'FaceAlpha', 0.35, 'EdgeColor', 'none', ...
              'Normalization', 'probability');

    % Real fold scores as vertical strip
    jitter = (rand(nFolds,1) - 0.5) * 0.015 * range(edges);
    yyaxis(ax, 'right');
    ax.YAxis(2).Color = GREEN;
    scatter(ax, allReal, jitter, 50, GREEN, 'filled', ...
            'MarkerEdgeColor', BLACK, 'LineWidth', 0.5);
    yline(ax, 0, 'Color', [GREEN 0.2], 'LineWidth', 0.5);
    ylabel(ax, 'Fold scores', 'Color', GREEN);

    yyaxis(ax, 'left');
    ax.YAxis(1).Color = GREEN * 0.6;
    ylabel(ax, 'Null density', 'Color', GREEN*0.6);

    % p-value: fraction of null >= mean real
    pVal = mean(allNull >= mean(allReal));
    xlabel(ax, 'Score  (R²)', 'Color', GREEN);
    outerTag = '';
    if ~isempty(outerID), outerTag = sprintf('  [%s]', outerID); end
    title(ax, sprintf('CV results: %s%s   (p = %.3f)', srcKey, outerTag, pVal), ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9);
end
