function fig = plot_bandHierarchyGrid(results, valueCol, sigThreshold, nexon, label, climLimsOverride)
% plot_bandHierarchyGrid  Dark-mode heatmap visualization of a
% build_bandHierarchy results table.
%
%   results      : output of build_bandHierarchy (one row per grid cell:
%                  band [x chans] x t, plus the metric columns)
%   valueCol     : optional, default 'conditionEffect_p_corrected'. Any
%                  column name containing 'p_' is plotted as -log10(p)
%                  (sequential 'hot' colormap, brighter = more
%                  significant); anything else (e.g. 'conditionEffect')
%                  is plotted as-is on a diverging colormap centered at 0.
%   sigThreshold : optional, default 0.05. Cells with
%                  conditionEffect_p_corrected < sigThreshold get a '*'
%                  overlay -- ALWAYS based on the corrected column,
%                  regardless of which column valueCol is coloring by, so
%                  the stars mean the same thing no matter what you're
%                  looking at. Pass [] to suppress the overlay entirely
%                  (e.g. for a table that doesn't have the column).
%   nexon        : optional, default []. Root Nexon handle (e.g.
%                  mdlObj.nexon) -- when supplied, any grid axis whose
%                  name matches nexVisualization_bar.m's own region-type
%                  check (dropout/chans/map, after stripping a leading
%                  "region") gets its levels reordered deep -> shallow via
%                  nexOp_regionDepthOrder, the SAME convention nexObj_bar
%                  uses, instead of plain encounter-order. Also supplies
%                  nexon.settings.Colors.cyberGreen as the heatmaps' accent
%                  color (sequential p-value map, and the diverging
%                  effect-size map's positive end) in place of the default
%                  red -- falls back to the same literal startNexus.m
%                  seeds it with if nexon is omitted.
%   label        : optional, default "". Prepended to the printed
%                  significant-cell table/per-region summary this function
%                  dumps to the console (e.g. a stratum name like
%                  "postCCI_L") so output from multiple calls stays
%                  distinguishable when scrolled back through.
%   climLimsOverride : optional, default []. [lo, hi] color-axis limits to
%                  use instead of auto-scaling to this call's own data --
%                  pass the same pair across several plot_bandHierarchyGrid
%                  calls (e.g. one per CCI/side stratum, via
%                  compute_bandHierarchyClim) so every one renders on an
%                  identical scale and a "bright" cell means the same
%                  thing in every figure. Omit (or []) to auto-scale to
%                  this call's own results, as before.
%
%   fig : the created figure handle.
%
% Handles exactly 2 grid dimensions (e.g. globalResults: band x t -- a
% single heatmap) or 3 (e.g. the full region screen: band x chans x t --
% one heatmap panel per band, chans x t within each).

    if nargin < 2 || isempty(valueCol), valueCol = 'conditionEffect_p_corrected'; end
    if nargin < 3, sigThreshold = 0.05; end
    if nargin < 4, nexon = []; end
    if nargin < 5 || isempty(label), label = ""; end
    if nargin < 6, climLimsOverride = []; end
    if ~ismember(valueCol, results.Properties.VariableNames)
        error('plot_bandHierarchyGrid:badValueCol', '"%s" is not a column of results.', valueCol);
    end
    hasSigCol = ismember('conditionEffect_p_corrected', results.Properties.VariableNames);
    if ~isempty(sigThreshold) && ~hasSigCol
        fprintf(['[plot_bandHierarchyGrid] no conditionEffect_p_corrected column -- ' ...
                 'skipping significance stars.\n']);
        sigThreshold = [];
    end

    metricCols = {'p_conditionFixed','p_conditionRandomSlope','conditionEffect', ...
                  'conditionEffect_p','conditionEffect_p_corrected'};
    gridVars = setdiff(results.Properties.VariableNames, metricCols, 'stable');

    cyberGreen = resolveCyberGreen(nexon);

    isPValue = contains(valueCol, 'p_');
    vals = results.(valueCol);
    if isPValue
        plotVals = -log10(max(vals, eps));
        cLabel  = sprintf('-log10(%s)', valueCol);
        cmap    = sequentialColormap(cyberGreen);
        if ~isempty(climLimsOverride)
            climLims = climLimsOverride;
        else
            finiteVals = plotVals(isfinite(plotVals));
            hi = max(finiteVals, [], 'omitnan');
            if isempty(hi) || hi <= 0, hi = 1; end
            climLims = [0, hi];
        end
    else
        plotVals = vals;
        cLabel  = valueCol;
        cmap    = divergingColormap(cyberGreen);
        if ~isempty(climLimsOverride)
            climLims = climLimsOverride;
        else
            m = max(abs(plotVals), [], 'omitnan');
            if isempty(m) || m == 0, m = 1; end
            climLims = [-m, m];
        end
    end

    DARK_BG = [0.11 0.11 0.13];
    DARK_AX = [0.16 0.16 0.18];
    TEXT_C  = [0.90 0.90 0.90];

    if hasSigCol, sigVals = results.conditionEffect_p_corrected; else, sigVals = []; end

    if numel(gridVars) == 2
        rowVar = gridVars{1}; colVar = gridVars{2};
        rowLevels = orderLevels(nexon, rowVar, results.(rowVar));
        colLevels = orderLevels(nexon, colVar, results.(colVar));
        M = gridToMatrix(results, plotVals, rowVar, rowLevels, colVar, colLevels);

        fig = figure('Color', DARK_BG, 'Position', [100 100 700 500]);
        ax = axes(fig);
        drawHeatmap(ax, M, rowLevels, colLevels, rowVar, colVar, cmap, climLims, DARK_AX, TEXT_C);
        if ~isempty(sigThreshold)
            Msig = gridToMatrix(results, sigVals, rowVar, rowLevels, colVar, colLevels);
            drawSigStars(ax, Msig, sigThreshold);
        end
        cb = colorbar(ax); cb.Label.String = cLabel; cb.Color = TEXT_C;
        title(ax, cLabel, 'Color', TEXT_C, 'Interpreter', 'none');

    elseif numel(gridVars) == 3
        panelVar = gridVars{1}; rowVar = gridVars{2}; colVar = gridVars{3};
        panelLevels = orderLevels(nexon, panelVar, results.(panelVar));
        rowLevels   = orderLevels(nexon, rowVar, results.(rowVar));
        colLevels   = orderLevels(nexon, colVar, results.(colVar));
        nPanels = numel(panelLevels);
        nCols = min(nPanels, 3);
        nRows = ceil(nPanels / nCols);

        fig = figure('Color', DARK_BG, 'Position', [50 50 420*nCols 300*nRows]);
        tl  = tiledlayout(fig, nRows, nCols, 'TileSpacing', 'compact', 'Padding', 'compact');
        ax  = gobjects(1, nPanels);
        for pi = 1:nPanels
            ax(pi) = nexttile(tl);
            mask0 = results.(panelVar) == panelLevels(pi);
            M = gridToMatrix(results(mask0, :), plotVals(mask0), rowVar, rowLevels, colVar, colLevels);
            drawHeatmap(ax(pi), M, rowLevels, colLevels, rowVar, colVar, cmap, climLims, DARK_AX, TEXT_C);
            if ~isempty(sigThreshold)
                Msig = gridToMatrix(results(mask0, :), sigVals(mask0), rowVar, rowLevels, colVar, colLevels);
                drawSigStars(ax(pi), Msig, sigThreshold);
            end
            title(ax(pi), char(panelLevels(pi)), 'Color', TEXT_C, 'Interpreter', 'none', 'FontSize', 10);
        end
        cb = colorbar(ax(end));
        cb.Layout.Tile = 'east';
        cb.Color = TEXT_C;
        cb.Label.String = cLabel;
        title(tl, cLabel, 'Color', TEXT_C, 'Interpreter', 'none');

    else
        error('plot_bandHierarchyGrid:unsupportedGrid', ...
            'Expected 2 or 3 grid dimensions, found %d (%s).', numel(gridVars), strjoin(gridVars, ', '));
    end
    set(fig, 'InvertHardcopy', 'off');

    if hasSigCol && ~isempty(sigThreshold)
        printSignificantCells(results, gridVars, sigThreshold, label);
    end
end

function printSignificantCells(results, gridVars, sigThreshold, label)
% printSignificantCells  Console dump of every cell surviving FDR
% correction (full row: grid coords + effect + raw/corrected p), plus a
% per-region rollup (count of significant cells and best p_corrected per
% region) when 'chans' is one of the grid dimensions -- the gray-matter-
% vs-white-matter dissociation question is fundamentally a per-region
% question, not just a per-cell one.
    if label ~= "", labelPrefix = char(label) + ": "; else, labelPrefix = ""; end
    sigMask = results.conditionEffect_p_corrected < sigThreshold;
    nSig = nnz(sigMask);
    fprintf('\n[plot_bandHierarchyGrid] %s%d/%d cell(s) significant at p_corrected < %.3g\n', ...
        labelPrefix, nSig, height(results), sigThreshold);
    printCols = [gridVars, {'conditionEffect', 'conditionEffect_p', 'conditionEffect_p_corrected'}];
    if nSig > 0
        sigRows = sortrows(results(sigMask, printCols), 'conditionEffect_p_corrected');
        disp(sigRows);
    end

    if ismember('chans', gridVars)
        [regionList, ~, ridx] = unique(results.chans, 'stable');
        nSigPerRegion   = accumarray(ridx, sigMask, [numel(regionList), 1]);
        minPPerRegion   = accumarray(ridx, results.conditionEffect_p_corrected, [numel(regionList), 1], @min);
        regionSummary = table(regionList, nSigPerRegion, minPPerRegion, ...
            'VariableNames', {'chans', 'nSigCells', 'minP_corrected'});
        regionSummary = sortrows(regionSummary, 'minP_corrected');
        fprintf('[plot_bandHierarchyGrid] %sper-region summary (sorted by best p_corrected):\n', labelPrefix);
        disp(regionSummary);
    end
end

function levels = orderLevels(nexon, axisName, vals)
% orderLevels  Level ordering for one grid axis, in order:
%  1. If every level parses cleanly as a number (e.g. "t"'s time-window
%     labels, stored as strings the same way build_bandPowerRegionTable's
%     conditionVar was -- categorical's own default category order is
%     lexicographic-string, not numeric, so "-1.012" sorts before
%     "-2.012" wrongly), sort by numeric value instead.
%  2. Else, plain unique(...,'stable') (encounter order).
%  3. UNLESS nexon is supplied and axisName is a region-type axis, in
%     which case levels are reordered deep -> shallow via
%     nexOp_regionDepthOrder regardless of (1)/(2) -- the exact same
%     convention nexVisualization_bar.m uses for its own region/chans
%     axes (axID = regexprep(lower(bareAx),'^region',''); isRegionType =
%     ismember(axID, ["dropout","chans","map"])). Region names never
%     parse as numbers, so (1)/(3) never actually compete in practice.
    levels    = unique(vals, 'stable');
    orderDesc = 'encounter';
    numericVals = str2double(string(levels));
    if ~isempty(numericVals) && ~any(isnan(numericVals))
        [~, numOrder] = sort(numericVals);
        levels    = levels(numOrder);
        orderDesc = 'numeric';
    end

    if isempty(nexon)
        fprintf('[plot_bandHierarchyGrid] "%s": no nexon supplied -- %s order\n', axisName, orderDesc);
        return;
    end
    axID = regexprep(lower(axisName), '^region', '');
    if ~ismember(axID, ["dropout", "chans", "map"])
        fprintf('[plot_bandHierarchyGrid] "%s": not a region-type axis -- %s order\n', axisName, orderDesc);
        return;
    end
    try
        ordered = nexOp_regionDepthOrder(nexon, levels);
        if isequal(string(ordered), string(levels)')
            fprintf(['[plot_bandHierarchyGrid] "%s": nexOp_regionDepthOrder returned the same ' ...
                     'order it was given -- likely no regMap match (empty registry/selection, or ' ...
                     'none of {%s} found in regMap.region). Levels: %s\n'], ...
                axisName, strjoin(cellstr(string(levels)), ', '), strjoin(cellstr(string(ordered)), ', '));
        else
            fprintf('[plot_bandHierarchyGrid] "%s": depth-ordered -> %s\n', ...
                axisName, strjoin(cellstr(string(ordered)), ', '));
        end
        levels = ordered;
    catch e
        fprintf('[plot_bandHierarchyGrid] "%s": nexOp_regionDepthOrder threw (%s) -- encounter order\n', ...
            axisName, e.message);
    end
end

function M = gridToMatrix(T, vals, rowVar, rowLevels, colVar, colLevels)
    M = nan(numel(rowLevels), numel(colLevels));
    for ri = 1:numel(rowLevels)
        for ci = 1:numel(colLevels)
            mask = T.(rowVar) == rowLevels(ri) & T.(colVar) == colLevels(ci);
            idx = find(mask, 1);
            if ~isempty(idx), M(ri, ci) = vals(idx); end
        end
    end
end

function drawHeatmap(ax, M, rowLevels, colLevels, rowVar, colVar, cmap, climLims, bgColor, textColor)
    imagesc(ax, M, climLims);
    colormap(ax, cmap);
    set(ax, 'XTick', 1:numel(colLevels), 'XTickLabel', cellstr(string(colLevels)), ...
            'YTick', 1:numel(rowLevels), 'YTickLabel', cellstr(string(rowLevels)), ...
            'Color', bgColor, 'XColor', textColor, 'YColor', textColor, ...
            'FontSize', 8, 'TickLabelInterpreter', 'none');
    xlabel(ax, colVar, 'Color', textColor, 'Interpreter', 'none');
    ylabel(ax, rowVar, 'Color', textColor, 'Interpreter', 'none');
    axis(ax, 'tight');
end

function drawSigStars(ax, Msig, sigThreshold)
% Overlay a bold black '*' centered on every cell where Msig < threshold.
% Black reads clearly against both colormaps used here: the sequential
% p-value map's significant cells are necessarily bright (near-white) by
% construction, and the diverging effect-size map's endpoints were chosen
% to avoid true black/saturated darkness (see divergingColormap), so black
% never disappears into the cell it's marking.
    hold(ax, 'on');
    [rIdx, cIdx] = find(Msig < sigThreshold);
    for k = 1:numel(rIdx)
        text(ax, cIdx(k), rIdx(k), '*', 'Color', 'k', 'FontWeight', 'bold', ...
            'FontSize', 16, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
    hold(ax, 'off');
end

function cmap = divergingColormap(posColor)
% Blue (negative) -> light neutral (zero) -> posColor (positive, default
% Nexus's own cyberGreen). Endpoints avoid pure white/black so it still
% reads clearly against a dark figure.
    if nargin < 1 || isempty(posColor), posColor = [0.24, 0.94, 0.46]; end
    n = 128;
    neg = [linspace(0.20,0.85,n)', linspace(0.40,0.85,n)', linspace(0.90,0.85,n)'];
    pos = [linspace(0.85,posColor(1),n)', linspace(0.85,posColor(2),n)', linspace(0.85,posColor(3),n)'];
    cmap = [neg; pos];
end

function cmap = sequentialColormap(baseColor)
% Black -> baseColor -> white (default Nexus's own cyberGreen) -- same
% 3-stop shape as the built-in 'hot' colormap it replaces, just hued to
% baseColor instead of red, so "brighter = more significant" still reads
% the same way.
    if nargin < 1 || isempty(baseColor), baseColor = [0.24, 0.94, 0.46]; end
    n = 128;
    seg1 = [linspace(0, baseColor(1), n)', linspace(0, baseColor(2), n)', linspace(0, baseColor(3), n)'];
    seg2 = [linspace(baseColor(1), 1, n)', linspace(baseColor(2), 1, n)', linspace(baseColor(3), 1, n)'];
    cmap = [seg1; seg2];
end

function c = resolveCyberGreen(nexon)
% resolveCyberGreen  nexon.settings.Colors.cyberGreen when available,
% falling back to the same literal startNexus.m seeds it with so these
% heatmaps match the Nexus brand accent color even without a live nexon.
    c = [0.24, 0.94, 0.46];
    if isempty(nexon), return; end
    try
        c = nexon.settings.Colors.cyberGreen;
    catch
    end
end
