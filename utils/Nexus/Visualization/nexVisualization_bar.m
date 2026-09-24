function nexVisualization_bar(nexObj, args) %#ok<INUSD>
% Render the active SRC result as a nested bar chart into nexObj's canvas.
% CTG (ordered selection) drives nesting via nexStat_binSTAT; VW filters
% which rows are included; CLR resolves per-bar color via the shared
% resolveGroupColors machinery (LUT/atlas/HSV three-tier resolution,
% hierarchical blending across multiple CLR selections — same as every
% other nexObject, no new color logic here); Pointer windows any axis
% other than fold/perm to a single value. fold is aggregated into the bar
% (mean ± SEM); perm becomes a null reference band (mean / 95th
% percentile) — one call per row into nexOp_barStatFromScores.
%
% Persistent handles: unlike nexObj_categorical/nexDraw_violin (cla() +
% full regenerate every call), this holds one Bar/ErrorBar/two ConstantLine
% handle on nexObj.Figure.barPlot, created once and updated in place
% (XData/YData/CData/Value) on every subsequent call — cheap because a
% single bar() object natively represents a whole group of bars (per-bar
% color via FaceColor='flat'+CData), unlike monoGraph's per-row line
% objects which need a real keyed handle registry.
%
% Nesting tiers are rendered as a multi-line XTickLabel per bar (outer
% tier first line, innermost tier last line closest to the axis) rather
% than nexDraw_violin's stacked-overlay-axes trick — the canvas here is a
% UIAxes inside a uifigure/tiledlayout, and layering plain axes() objects
% on top of that is not a supported combination.

    BLACK = [0 0 0];
    GREEN = resolveGreen(nexObj);
    GRAY  = [0.5 0.5 0.5];
    ax    = nexObj.Figure.panel0.tiles.ax;
    [hBar, hErr, hNullMu, hNullHi] = ensureBarHandles(nexObj, ax, BLACK, GRAY);

    bus = nexObj.collector.View;
    srcSel = bus.selections.SRC;
    if isempty(srcSel) || isempty(bus.selKeys.SRC)
        setVisible(hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end
    srcKey = char(bus.selKeys.SRC(min(srcSel(end), numel(bus.selKeys.SRC))));
    if ~isfield(nexObj.RESULTS, srcKey)
        setVisible(hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end
    R = nexObj.RESULTS.(srcKey);
    if ~istable(R) || height(R) == 0
        setVisible(hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end

    % VW row filter
    vwSel  = bus.selections.VW;
    vwVals = string.empty;
    if ~isempty(vwSel) && ~isempty(bus.selKeys.VW)
        vwSel  = vwSel(vwSel >= 1 & vwSel <= numel(bus.selKeys.VW));
        vwVals = string(bus.selKeys.VW(vwSel));
    end
    rowIdx = nexObj.filterResultsByVW(R, vwVals);
    R = R(rowIdx, :);
    if height(R) == 0
        setVisible(hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end

    % CTG nesting order (outer tier first, per selection order)
    ctgSel  = bus.selections.CTG;
    ctgCols = string.empty;
    if ~isempty(ctgSel) && ~isempty(bus.selKeys.CTG)
        ctgSel  = ctgSel(ctgSel >= 1 & ctgSel <= numel(bus.selKeys.CTG));
        ctgCols = string(bus.selKeys.CTG(ctgSel));
    end

    % Per-row bar value/error + null reference, at the current Pointer position
    nRows  = height(R);
    barVal = nan(nRows, 1);
    barErr = nan(nRows, 1);
    nullMu = nan(nRows, 1);
    nullHi = nan(nRows, 1);
    for i = 1:nRows
        try
            [barVal(i), barErr(i), nullMu(i), nullHi(i)] = nexOp_barStatFromScores( ...
                R.df{i}, R.ax{i}, R.ptr{i}, nexObj.collector.Pointer);
        catch e
            fprintf('[nexVisualization_bar] row %d: %s\n', i, e.message);
        end
    end
    valid  = ~isnan(barVal);
    R      = R(valid, :);
    barVal = barVal(valid); barErr = barErr(valid);
    nullMu = nullMu(valid); nullHi = nullHi(valid);
    if isempty(barVal)
        setVisible(hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end

    % Nested bar positions
    if ~isempty(ctgCols)
        [X, xTicks, xLabels] = nexStat_binSTAT(R, ctgCols);
    else
        X = (1:height(R))';
        xTicks = {}; xLabels = {};
    end
    [Xs, ord] = sort(X);

    % Per-bar color — same resolveGroupColors path every other nexObject's
    % RESULTS-branch rendering uses (see nexVisualization_monoGraph).
    clrSel  = bus.selections.CLR;
    clrCols = string.empty;
    if ~isempty(clrSel) && ~isempty(bus.selKeys.CLR)
        clrSel  = clrSel(clrSel >= 1 & clrSel <= numel(bus.selKeys.CLR));
        clrCols = string(bus.selKeys.CLR(clrSel));
    end
    if ~isempty(clrCols)
        colors = nexObj.resolveGroupColors(R, clrCols);
    elseif height(R) > 1
        colors = nexVis_hsvSpread(height(R));
    else
        colors = GREEN;
    end

    set(hBar, 'XData', Xs, 'YData', barVal(ord), 'FaceColor', 'flat', ...
        'CData', colors(ord, :), 'Visible', 'on');
    set(hErr, 'XData', Xs, 'YData', barVal(ord), ...
        'YNegativeDelta', barErr(ord), 'YPositiveDelta', barErr(ord), 'Visible', 'on');
    hNullMu.Value   = mean(nullMu, 'omitnan');
    hNullHi.Value   = mean(nullHi, 'omitnan');
    hNullMu.Visible = 'on';
    hNullHi.Visible = 'on';

    ylabel(ax, 'Balanced accuracy', 'Color', GREEN);
    title(ax, srcKey, 'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9, ...
          'Interpreter', 'none');

    % Per-bar nesting label: match each bar's own X against every tier's
    % own tick set (nexStat_binSTAT gives one {xTicks, xLabels} pair per
    % tier, sharing the same position space), join outer→inner as a
    % multi-line tick label.
    if ~isempty(xTicks)
        Xr = round(X, 10);
        nTiers = size(xTicks, 1);
        combined = strings(numel(X), 1);
        for ri = 1:numel(X)
            parts = strings(1, nTiers);
            for ti = 1:nTiers
                xTicks_ti = round(xTicks{ti, 1}, 10);
                m = find(Xr(ri) == xTicks_ti, 1);
                if ~isempty(m), parts(ti) = string(xLabels{ti}(m)); end
            end
            parts = parts(parts ~= "");
            combined(ri) = strjoin(parts, newline);
        end
        ax.XTick      = Xs;
        ax.XTickLabel = cellstr(combined(ord));
    else
        ax.XTick      = Xs;
        ax.XTickLabel = {};
    end
end


function [hBar, hErr, hNullMu, hNullHi] = ensureBarHandles(nexObj, ax, BLACK, GRAY)
% Lazily create the persistent bar/errorbar/null-band handles once; every
% later call reuses (updates in place) rather than cla()-and-rebuild.
    if isfield(nexObj.Figure, 'barPlot') && isstruct(nexObj.Figure.barPlot) && ...
            isfield(nexObj.Figure.barPlot, 'hBar') && isvalid(nexObj.Figure.barPlot.hBar)
        p = nexObj.Figure.barPlot;
        hBar = p.hBar; hErr = p.hErr; hNullMu = p.hNullMu; hNullHi = p.hNullHi;
        return;
    end
    hBar    = bar(ax, nan, nan, 0.6, 'FaceColor', 'flat', 'EdgeColor', BLACK);
    hErr    = errorbar(ax, nan, nan, nan, 'LineStyle', 'none', 'Color', BLACK, 'CapSize', 4);
    hNullMu = yline(ax, 0, '--', 'Color', GRAY, 'LineWidth', 1);
    hNullHi = yline(ax, 0, ':',  'Color', GRAY, 'LineWidth', 1);
    nexObj.Figure.barPlot = struct('hBar', hBar, 'hErr', hErr, ...
                                    'hNullMu', hNullMu, 'hNullHi', hNullHi);
end

function setVisible(hBar, hErr, hNullMu, hNullHi, v)
    if isvalid(hBar),    hBar.Visible    = v; end
    if isvalid(hErr),    hErr.Visible    = v; end
    if isvalid(hNullMu), hNullMu.Visible = v; end
    if isvalid(hNullHi), hNullHi.Visible = v; end
end

function GREEN = resolveGreen(nexObj)
    try
        GREEN = nexObj.nexon.settings.Colors.cyberGreen;
    catch
        GREEN = [0.18 0.8 0.44];
    end
end
