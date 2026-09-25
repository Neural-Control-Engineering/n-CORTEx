function nexVisualization_bar(nexObj, args) %#ok<INUSD>
% Render the active SRC result as a nested bar chart into nexObj's canvas.
% CTG (ordered selection) drives nesting via nexStat_binSTAT; VW filters
% which rows are included; CLR resolves per-bar color via the shared
% resolveGroupColors machinery (LUT/atlas/HSV three-tier resolution,
% hierarchical blending across multiple CLR selections — same as every
% other nexObject, no new color logic here); Pointer windows any axis
% other than fold/perm to a single value — EXCEPT one designated "expand"
% axis (resolveExpandAxis below), whose multi-item Pointer selection
% instead becomes its own innermost nesting tier, one bar per selected
% item, alongside CTG (2D nested bars — see WIP.md for the further,
% not-yet-implemented step of nesting more than one axis this way at
% once, a true 3D/"lego" bar chart). fold is aggregated into each bar
% (mean ± SEM); perm becomes a null reference band (mean / 95th
% percentile) — one call per (row × expand-axis item) into
% nexOp_barStatFromScores.
%
% Persistent handles: unlike nexObj_categorical/nexDraw_violin (cla() +
% full regenerate every call), this holds one Bar/ErrorBar/two ConstantLine
% handle on nexObj.Figure.barPlot, created once and updated in place
% (XData/YData/CData/Value) on every subsequent call — cheap because a
% single bar() object natively represents a whole group of bars (per-bar
% color via FaceColor='flat'+CData), unlike monoGraph's per-row line
% objects which need a real keyed handle registry.
%
% Nesting tiers are rendered as true spanning group headers — the
% innermost tier is the axis's own XTickLabel (one label per bar, read
% directly off each bar's own row/tier values — no position-matching
% against nexStat_binSTAT's own xTicks/xLabels outputs, which are only
% sparse per-tier group boundaries, not one entry per bar); every OUTER
% tier gets ONE text() label per contiguous run of bars sharing that
% tier's value, centered over the run and stacked progressively further
% below the axis (outermost tier furthest down) — see updateTierHeaders.
% This is the same "one label per group, not per bar" idea as
% nexDraw_violin's stacked-overlay-axes trick, done with text()
% annotations on the one UIAxes instead, since a UIAxes inside a
% uifigure/tiledlayout can't be layered with extra plain axes() objects
% the way nexDraw_violin's canvas can.

    BLACK = [0 0 0];
    GREEN = resolveGreen(nexObj);
    GRAY  = [0.5 0.5 0.5];
    ax    = nexObj.Figure.panel0.tiles.ax;
    [hBar, hErr, hNullMu, hNullHi] = ensureBarHandles(nexObj, ax, BLACK, GRAY, GREEN);

    bus = nexObj.collector.View;
    srcSel = bus.selections.SRC;
    if isempty(srcSel) || isempty(bus.selKeys.SRC)
        setVisible(nexObj, hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end
    srcKey = char(bus.selKeys.SRC(min(srcSel(end), numel(bus.selKeys.SRC))));
    if ~isfield(nexObj.RESULTS, srcKey)
        setVisible(nexObj, hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end
    R = nexObj.RESULTS.(srcKey);
    if ~istable(R) || height(R) == 0
        setVisible(nexObj, hBar, hErr, hNullMu, hNullHi, 'off'); return;
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
        setVisible(nexObj, hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end

    % CTG nesting order (outer tier first, per selection order)
    ctgSel  = bus.selections.CTG;
    ctgCols = string.empty;
    if ~isempty(ctgSel) && ~isempty(bus.selKeys.CTG)
        ctgSel  = ctgSel(ctgSel >= 1 & ctgSel <= numel(bus.selKeys.CTG));
        ctgCols = string(bus.selKeys.CTG(ctgSel));
    end

    % Pick (at most) one Pointer axis to expand into its own nesting tier
    % instead of collapsing its multi-item selection into a mean — see
    % resolveExpandAxis for the "only one, first by field order" scoping.
    ptrBus     = nexObj.collector.Pointer;
    expandAxis = resolveExpandAxis(R, ptrBus);

    % Per-row bar value/error + null reference, at the current Pointer
    % position. Each row expands into ONE bar per kept item along
    % expandAxis (or a single bar, same as before, when expandAxis == "").
    % Grown rather than preallocated Nx1 since the final bar count isn't
    % known until every row's own expansion is resolved.
    nRows        = height(R);
    barVal       = [];
    barErr       = [];
    nullMu       = [];
    nullHi       = [];
    rowSel       = [];          % which R row each bar came from
    expandLabels = string.empty(0, 1);
    for i = 1:nRows
        try
            [v, e, nMu, nHi, lbls] = nexOp_barStatFromScores( ...
                R.df{i}, R.ax{i}, R.ptr{i}, ptrBus, expandAxis);
            v = v(:); e = e(:); nMu = nMu(:); nHi = nHi(:); lbls = lbls(:);
            barVal = [barVal; v]; barErr = [barErr; e]; %#ok<AGROW>
            nullMu = [nullMu; nMu]; nullHi = [nullHi; nHi]; %#ok<AGROW>
            rowSel = [rowSel; repmat(i, numel(v), 1)]; %#ok<AGROW>
            expandLabels = [expandLabels; lbls]; %#ok<AGROW>
        catch e2
            fprintf('[nexVisualization_bar] row %d: %s\n', i, e2.message);
        end
    end
    valid  = ~isnan(barVal);
    rowSel = rowSel(valid);
    barVal = barVal(valid); barErr = barErr(valid);
    nullMu = nullMu(valid); nullHi = nullHi(valid);
    expandLabels = expandLabels(valid);
    if isempty(barVal)
        setVisible(nexObj, hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end

    % One R row per bar now (replicated per expand-axis item when active).
    % expandAxis becomes the innermost CTG tier — appended last, matching
    % nexStat_binSTAT's "outer tier first" convention for the existing
    % CTG columns.
    R = R(rowSel, :);
    if expandAxis ~= ""
        expandCol = expandAxis;
        if ismember(expandCol, string(R.Properties.VariableNames))
            expandCol = "swp_" + expandCol;   % avoid clobbering an existing column of the same name
        end
        R.(char(expandCol)) = expandLabels;
        ctgCols = [ctgCols, expandCol];
    end

    % Nested bar positions — only X is needed; xTicks/xLabels are sparse
    % per-tier group boundaries, not one entry per bar, so they're no use
    % for per-bar labeling (see updateTierHeaders, which reads tier values
    % straight off R's own columns instead).
    if ~isempty(ctgCols)
        X = nexStat_binSTAT(R, ctgCols);
    else
        X = (1:height(R))';
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

    % Per-bar nesting labels: innermost tier (last column) drives the
    % axis's own XTickLabel, one label per bar; every outer tier is
    % rendered separately by updateTierHeaders as spanning group headers.
    % Read straight from R's own tier columns, in the same sorted (ord)
    % order as Xs/barVal — no coordinate matching, so always correct
    % regardless of nexStat_binSTAT's internal tick spacing.
    nTiers   = numel(ctgCols);
    tierVals = strings(numel(Xs), nTiers);
    for t = 1:nTiers
        tierVals(:, t) = string(R.(char(ctgCols(t)))(ord));
    end
    ax.XTick = Xs;
    if nTiers > 0
        ax.XTickLabel = cellstr(tierVals(:, end));
    else
        ax.XTickLabel = {};
    end
    updateTierHeaders(nexObj, ax, Xs, tierVals, GREEN);
end


function [hBar, hErr, hNullMu, hNullHi] = ensureBarHandles(nexObj, ax, BLACK, GRAY, GREEN)
% Lazily create the persistent bar/errorbar/null-band handles once; every
% later call reuses (updates in place) rather than cla()-and-rebuild.
    if isfield(nexObj.Figure, 'barPlot') && isstruct(nexObj.Figure.barPlot) && ...
            isfield(nexObj.Figure.barPlot, 'hBar') && isvalid(nexObj.Figure.barPlot.hBar)
        p = nexObj.Figure.barPlot;
        hBar = p.hBar; hErr = p.hErr; hNullMu = p.hNullMu; hNullHi = p.hNullHi;
        return;
    end
    hBar    = bar(ax, nan, nan, 0.6, 'FaceColor', 'flat', 'EdgeColor', BLACK);
    hErr    = errorbar(ax, nan, nan, nan, 'LineStyle', 'none', 'Color', GREEN, 'CapSize', 4);
    hNullMu = yline(ax, 0, '--', 'Color', GRAY, 'LineWidth', 1);
    hNullHi = yline(ax, 0, ':',  'Color', GRAY, 'LineWidth', 1);
    nexObj.Figure.barPlot = struct('hBar', hBar, 'hErr', hErr, ...
                                    'hNullMu', hNullMu, 'hNullHi', hNullHi, ...
                                    'tierLabels', gobjects(0));
end

function updateTierHeaders(nexObj, ax, Xs, tierVals, GREEN)
% Draw one text() label per contiguous run of bars sharing an OUTER
% tier's value (every column of tierVals except the last, which is the
% innermost tier already shown via the axis's own XTickLabel), centered
% over the run and stacked progressively further below the axis —
% outermost tier (column 1) furthest down. tierVals/Xs must already be in
% the SAME sorted (ord) order the bars themselves are drawn in, so a
% "contiguous run" here really does mean one visually adjacent group.
%
% Handles are deleted and recreated every call rather than updated in
% place — the number of runs varies with the data/selection, so there is
% no fixed slot to update, and this set is small relative to everything
% else already recomputed per call.
%
% barPlot itself may predate this field (a figure already open from
% before tierLabels was added to ensureBarHandles's struct literal —
% its early-return branch never revisits an existing struct) — isfield,
% not direct access, so an older-shaped struct doesn't error here.
    if isfield(nexObj.Figure.barPlot, 'tierLabels')
        old = nexObj.Figure.barPlot.tierLabels;
        for i = 1:numel(old)
            if isvalid(old(i)), delete(old(i)); end
        end
    end
    handles = gobjects(0);
    nTiers  = size(tierVals, 2);
    if nTiers > 1 && ~isempty(Xs)
        try, ax.Clipping = 'off'; catch, end
        yr    = ax.YLim;
        yspan = max(diff(yr), eps);
        for t = 1:(nTiers - 1)
            vals     = tierVals(:, t);
            level    = nTiers - t;   % outermost tier -> largest level -> furthest below axis
            yOff     = yr(1) - level * 0.08 * yspan;
            changeAt = find(vals(2:end) ~= vals(1:end-1));
            runStart = [1; changeAt + 1];
            runEnd   = [changeAt; numel(vals)];
            for r = 1:numel(runStart)
                xc = mean(Xs(runStart(r):runEnd(r)));
                h  = text(ax, xc, yOff, char(vals(runStart(r))), ...
                          'Color', GREEN, 'FontSize', 9, ...
                          'HorizontalAlignment', 'center', 'Clipping', 'off');
                handles(end+1) = h; %#ok<AGROW>
            end
        end
    end
    nexObj.Figure.barPlot.tierLabels = handles;
end

function setVisible(nexObj, hBar, hErr, hNullMu, hNullHi, v)
    if isvalid(hBar),    hBar.Visible    = v; end
    if isvalid(hErr),    hErr.Visible    = v; end
    if isvalid(hNullMu), hNullMu.Visible = v; end
    if isvalid(hNullHi), hNullHi.Visible = v; end
    try
        tl = nexObj.Figure.barPlot.tierLabels;
        for i = 1:numel(tl)
            if isvalid(tl(i)), tl(i).Visible = v; end
        end
    catch
    end
end

function expandAxis = resolveExpandAxis(R, ptrBus)
% Pick the (at most one) Pointer axis to expand into its own nesting tier
% instead of averaging its multi-item selection away — the FIRST axis (by
% field order in R.ax{1}, excluding fold/perm) with a genuine multi-item,
% non-"select all" Pointer selection. Any OTHER axis that also happens to
% have a multi-item selection still collapses via mean inside
% nexOp_barStatFromScores, same as before this was added — true
% simultaneous nesting across more than one axis (a 3D/"lego" bar chart)
% is a bigger step, deliberately not done here (see WIP.md).
%
%   R      : the (VW-filtered) RESULTS table — R.ax{1} gives this
%            result's axis fields
%   ptrBus : nexObj.collector.Pointer
%
%   expandAxis : "" (no axis qualifies) or the chosen axis name (string)
    expandAxis = "";
    if height(R) == 0, return; end
    axFields = setdiff(fieldnames(R.ax{1}), {'fold', 'perm'}, 'stable');
    for k = 1:numel(axFields)
        f = axFields{k};
        if ~isfield(ptrBus.selections, f) || ~isfield(ptrBus.selKeys, f)
            continue;
        end
        selIdx  = ptrBus.selections.(f);
        allVals = ptrBus.selKeys.(f);
        if numel(selIdx) > 1 && numel(selIdx) < numel(allVals)
            expandAxis = string(f);
            return;
        end
    end
end

function GREEN = resolveGreen(nexObj)
    try
        GREEN = nexObj.nexon.settings.Colors.cyberGreen;
    catch
        GREEN = [0.18 0.8 0.44];
    end
end
