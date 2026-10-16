function nexVisualization_bar(nexObj, args) %#ok<INUSD>
% Render the active SRC result as a nested bar chart into nexObj's canvas.
% CTG (ordered selection) drives nesting via nexStat_binSTAT; VW filters
% which rows are included; CLR resolves per-bar color via the shared
% resolveGroupColors machinery (LUT/atlas/HSV three-tier resolution,
% hierarchical blending across multiple CLR selections — same as every
% other nexObject, no new color logic here); Pointer windows any axis
% other than fold/perm to a single value — EXCEPT any number of designated
% "expand" axes (resolveExpandAxes below), each of whose multi-item Pointer
% selection instead becomes its own nesting tier, alongside CTG. With more
% than one expand axis, bars are the full CARTESIAN PRODUCT across all of
% them (nexOp_barStatFromScores) — still a flat 1D bar chart with extra
% nested tier headers, same as stacking more CTG picks; NOT the true
% 3D/"lego" grid-with-height chart WIP.md used to describe as the only way
% past one axis (it isn't — this generalizes the existing nested-tier
% rendering instead of needing new geometry). fold is aggregated into each
% bar (mean ± SEM); perm becomes a null reference band (mean / 95th
% percentile) — one call per row into nexOp_barStatFromScores, which
% returns one bar per kept item-combination for that row.
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

    % Pick every Pointer axis with a genuine multi-item selection to
    % expand into its own nesting tier instead of collapsing it into a
    % mean — see resolveExpandAxes. Zero, one, or several axes; bars
    % become the cartesian product across however many qualify.
    ptrBus     = nexObj.collector.Pointer;
    expandAxes = resolveExpandAxes(R, ptrBus);
    % Optional user-facing OUTER<->INNER flip for expand-axis tiers only
    % (e.g. region/chans vs time) — CTG tier order is untouched, still
    % controlled by its own listbox item order. isprop guard: nexObj_bar
    % carries this property, but resolveExpandAxes/this file are generic
    % enough that a future non-bar caller shouldn't need it.
    if isprop(nexObj, 'reverseExpandOrder') && nexObj.reverseExpandOrder
        expandAxes = fliplr(expandAxes);
    end
    nExpand    = numel(expandAxes);

    % Per-row bar value/error + null reference, at the current Pointer
    % position. Each row expands into one bar per kept item-combination
    % across expandAxes (or a single bar, same as before, when expandAxes
    % is empty). Grown rather than preallocated since the final bar count
    % isn't known until every row's own expansion is resolved.
    nRows        = height(R);
    barVal       = [];
    barErr       = [];
    nullMu       = [];
    nullHi       = [];
    rowSel       = [];          % which R row each bar came from
    expandLabels = strings(0, nExpand);   % one column PER expand axis
    for i = 1:nRows
        try
            [v, e, nMu, nHi, lbls] = nexOp_barStatFromScores( ...
                R.df{i}, R.ax{i}, R.ptr{i}, ptrBus, expandAxes);
            v = v(:); e = e(:); nMu = nMu(:); nHi = nHi(:);
            barVal = [barVal; v]; barErr = [barErr; e]; %#ok<AGROW>
            nullMu = [nullMu; nMu]; nullHi = [nullHi; nHi]; %#ok<AGROW>
            rowSel = [rowSel; repmat(i, numel(v), 1)]; %#ok<AGROW>
            expandLabels = [expandLabels; lbls]; %#ok<AGROW>
        catch e2
            fprintf('[nexVisualization_bar] row %d: %s\n', i, e2.message);
        end
    end
    % A row whose own data only matched zero of some expand axis's bus-
    % level selection (plausible now that "select all" tests against the
    % full union of items — a given row/session may not have recorded
    % every one of them) comes back from nexOp_barStatFromScores as a
    % dropped row: a real (non-NaN) bar VALUE isn't guaranteed either, but
    % expandLabels is <missing> in every column for that row regardless.
    % Left in, a <missing> sentinel mixes into the tier column
    % nexStat_binSTAT groups on — MATLAB's <missing> string has NaN-like
    % equality (missing==missing is false), so ismember() never matches it
    % against anything, including itself, which crashes nexStat_binSTAT's
    % arrayfun ("Non-scalar in Uniform output") the first time a mixed
    % real/missing tier column occurs. There's no coherent expand-item
    % identity for such a row anyway, so it shouldn't produce a bar at
    % all — drop it the same way a NaN bar value already is. A row is
    % invalid if ANY of its expand axes came back missing, not just one.
    valid  = ~isnan(barVal) & ~any(ismissing(expandLabels), 2);
    rowSel = rowSel(valid);
    barVal = barVal(valid); barErr = barErr(valid);
    nullMu = nullMu(valid); nullHi = nullHi(valid);
    expandLabels = expandLabels(valid, :);
    if isempty(barVal)
        setVisible(nexObj, hBar, hErr, hNullMu, hNullHi, 'off'); return;
    end

    % One R row per bar now (replicated per kept item-combination when
    % active). Each expand axis becomes its own CTG-style tier — appended
    % last, in expandAxes' own (field-)order, matching nexStat_binSTAT's
    % "outer tier first" convention already used for CTG columns, so N
    % simultaneous expand axes are indistinguishable from N extra CTG
    % picks downstream (positioning, ordering, tier headers all just see
    % more columns — nothing about them is expand-axis-specific).
    R = R(rowSel, :);
    expandCols = string.empty(1, 0);
    for a = 1:nExpand
        axName    = expandAxes(a);
        expandCol = axName;
        if ismember(expandCol, string(R.Properties.VariableNames))
            expandCol = "swp_" + expandCol;   % avoid clobbering an existing column of the same name
        end
        R.(char(expandCol)) = expandLabels(:, a);
        expandCols(end+1)   = expandCol; %#ok<AGROW>

        % Co-indexed sibling (e.g. "chans" alongside "unit") — same
        % per-bar labels under the sibling's own name too, so a CLR
        % "ax--<sibling>" key (e.g. ax--chans, for atlas-registry
        % coloring — same lookup polyGraph uses) finds a real column here,
        % not just "ax--<axName>" itself. nexAnalysis_cvPermute packs the
        % sibling alongside the SWP axis's own field in R.ax when they're
        % co-indexed (e.g. FTR="unit" resolved via chans' own pMap entry);
        % only add the column when that's actually present.
        try
            coPairs = nexOp_coIndexPairs(R.ax{1});
            for p = 1:numel(coPairs)
                pair = coPairs{p};
                if ~ismember(axName, string(pair)), continue; end
                sib = string(pair(~strcmp(pair, axName)));
                if ~isempty(sib) && isfield(R.ax{1}, sib) && ...
                        ~ismember(sib, string(R.Properties.VariableNames))
                    R.(char(sib)) = expandLabels(:, a);
                end
            end
        catch
        end
    end
    ctgCols = [ctgCols, expandCols];

    % Canonical bar-position ordering — replace the default alphabetical/
    % encounter sort with a real ordinance where one exists. Applies to
    % every column feeding a bar-position tier, CTG picks and the expand
    % axis alike (both are "domain intersections" the user picks the same
    % way here). Two cases:
    %   - Numeric-valued tiers (e.g. time) — nexOp_barStatFromScores
    %     stringifies every expand-axis value before it becomes a STAT
    %     column (expandLabels = string(...)), so nexStat_binSTAT's default
    %     unique() sorts them as TEXT, not numbers — "-0.2" < "-0.7" < "-0.9"
    %     lexically (the '-' groups negatives first, then digit-by-digit
    %     comparison ignores the sign), which is backwards numerically.
    %     Sort the unique STRING values by their PARSED numeric value
    %     instead — never regenerate the string from the number, which
    %     could drift from the exact formatting actually stored.
    %   - Region/chans-type axes — atlas-registry depth order (deep, e.g.
    %     STN/HY, on the left -> shallow, e.g. CA/SSp/V1, on the right —
    %     nexOp_regionDepthOrder, same regMap.Y depth data
    %     nex_axisColorFromRegistry already uses for coloring). Checked
    %     only when NOT numeric — a raw numeric channel axis has no
    %     per-value registry match (same ambiguity
    %     nex_axisColorFromRegistry's own "chans" case resolves the same
    %     way, by checking whether the values parse as numbers).
    % Everything else (genuine categorical labels — subject, phase, ...)
    % is left at nexStat_binSTAT's default.
    orderMap = struct();
    for ci = 1:numel(ctgCols)
        col  = char(ctgCols(ci));
        vals = R.(col);

        numVals = str2double(vals);
        if ~isempty(numVals) && all(~isnan(numVals))
            [uniqVals, ia] = unique(vals);
            [~, ord] = sort(numVals(ia));
            orderMap.(col) = uniqVals(ord);
            continue;
        end

        bareAx = regexprep(col, '^swp_', '');   % strip collision-avoidance prefix (line ~129)
        axID   = regexprep(lower(bareAx), '^region', '');
        isRegionType = ismember(axID, ["dropout", "chans", "map"]);
        if ~isRegionType
            % Co-indexed sibling of "chans" (typically "unit") gets the
            % SAME region-name relabeling under mapID/region-mode pooling
            % (nexOp_poolAx: "mapID: inherit region labels" applies to
            % dependents too, not just the primary chans axis) — so a
            % bar tier named "unit" can carry region-name values just
            % like "chans" would, under its own field name.
            try
                coPairs = nexOp_coIndexPairs(R.ax{1});
                for p = 1:numel(coPairs)
                    pair = string(coPairs{p});
                    if ismember(bareAx, pair) && any(lower(pair) == "chans")
                        isRegionType = true;
                        break;
                    end
                end
            catch
            end
        end
        if ~isRegionType
            continue;
        end
        try
            orderMap.(col) = nexOp_regionDepthOrder(nexObj.nexon, vals);
        catch
        end
    end

    % Nested bar positions — only X is needed; xTicks/xLabels are sparse
    % per-tier group boundaries, not one entry per bar, so they're no use
    % for per-bar labeling (see updateTierHeaders, which reads tier values
    % straight off R's own columns instead).
    if ~isempty(ctgCols)
        X = nexStat_binSTAT(R, ctgCols, orderMap);
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

    % resolveGroupColors translates an "ax--X" CLR key to X's bare column
    % name and looks it up directly on R, silently skipping (-> falls
    % through to plain green) if no such column exists. R only ever gets
    % an X-named column from the expand-axis mechanism above, which only
    % fires for a genuine MULTI-item Pointer selection — a single picked
    % item (e.g. one region) never becomes its own tier, so "ax--chans"
    % had nothing to resolve against even though a real, unambiguous
    % value (the one Pointer-selected item) exists. Materialize that
    % column here for any ax--X key not already produced above: every bar
    % from row i shares the SAME single windowed value along a
    % non-expanding axis, so this is a per-ROW broadcast (not per-bar),
    % using the identical windowing idiom nexOp_barStatFromScores uses
    % internally for any axis it doesn't expand.
    for ci = 1:numel(clrCols)
        key = clrCols(ci);
        if ~startsWith(key, "ax--"), continue; end
        axName = extractAfter(key, "ax--");
        if ismember(axName, string(R.Properties.VariableNames)), continue; end
        if ~isfield(ptrBus.selections, axName) || ~isfield(ptrBus.selKeys, axName)
            continue;
        end
        try
            colVals = strings(height(R), 1);
            selIdx  = ptrBus.selections.(axName);
            allVals = ptrBus.selKeys.(axName);
            if isempty(selIdx), continue; end
            selVals = allVals(selIdx);
            for i = 1:height(R)
                ax_i = R.ax{i};
                if ~isfield(ax_i, axName), continue; end
                rowVals = ax_i.(axName);
                if isnumeric(selVals) && isnumeric(rowVals)
                    keep = ismember(rowVals, selVals);
                else
                    keep = ismember(string(rowVals), string(selVals));
                end
                keepIdx = find(keep, 1);
                if isempty(keepIdx), continue; end
                colVals(i) = string(rowVals(keepIdx));
            end
            R.(char(axName)) = colVals;
        catch
        end
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
        'YNegativeDelta', barErr(ord), 'YPositiveDelta', barErr(ord), 'Visible', 'on', ...
        'LineWidth', 2, 'CapSize', 4);   % set every redraw, not just at construction —
                                          % ensureBarHandles's "reuse existing handle"
                                          % branch never re-applies these otherwise,
                                          % so an already-open figure never picks up
                                          % a cosmetic-only change like this.
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
    % Baseline for the tier-header text, computed straight from the
    % PLOTTED DATA (bars +/- error, null band) rather than ax.YLim —
    % text() objects placed below the axis count toward MATLAB's auto
    % Y-limit calculation, so deriving this from ax.YLim on every redraw
    % created a feedback loop: each call's headers nudged the axis limits
    % down a bit, and the NEXT call read that already-lowered limit as its
    % new baseline, sinking further every redraw. Computing straight from
    % the numeric data is immune to that — it can never be influenced by
    % where the header text itself was drawn last time.
    %
    % Must include the bar chart's own BASELINE (bar() draws from there up
    % to each value, typically 0 — not from barVal-barErr, which is only
    % the error whisker's bottom, sitting well ABOVE the bar's actual base
    % for positive values) — omitting it put dataLo mid-air among the bar
    % tops instead of at the bars' true visual bottom, landing the headers
    % in the middle of the bars instead of below them.
    baseVal = 0;
    try, baseVal = hBar.BaseValue; catch, end
    dataLo = min([baseVal; barVal(:) - barErr(:); nullMu(:); nullHi(:)], [], 'omitnan');
    dataHi = max([baseVal; barVal(:) + barErr(:); nullMu(:); nullHi(:)], [], 'omitnan');
    dataSpan = max(dataHi - dataLo, eps);
    updateTierHeaders(nexObj, ax, Xs, tierVals, GREEN, dataLo, dataSpan);
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
    hErr    = errorbar(ax, nan, nan, nan, 'LineStyle', 'none', 'Color', GREEN, 'CapSize', 4, 'LineWidth', 2);
    hNullMu = yline(ax, 0, '--', 'Color', GRAY, 'LineWidth', 1);
    hNullHi = yline(ax, 0, ':',  'Color', GRAY, 'LineWidth', 1);
    nexObj.Figure.barPlot = struct('hBar', hBar, 'hErr', hErr, ...
                                    'hNullMu', hNullMu, 'hNullHi', hNullHi, ...
                                    'tierLabels', gobjects(0));
end

function updateTierHeaders(nexObj, ax, Xs, tierVals, GREEN, dataLo, dataSpan)
% Draw one text() label per contiguous run of bars sharing an OUTER
% tier's value (every column of tierVals except the last, which is the
% innermost tier already shown via the axis's own XTickLabel), centered
% over the run and stacked progressively further below the axis —
% outermost tier (column 1) furthest down. tierVals/Xs must already be in
% the SAME sorted (ord) order the bars themselves are drawn in, so a
% "contiguous run" here really does mean one visually adjacent group.
%
% dataLo/dataSpan are computed by the caller straight from the plotted
% DATA (bars +/- error, null band) — deliberately NOT ax.YLim. text()
% objects placed below the axis count toward MATLAB's auto Y-limit
% calculation, so a previous version that read ax.YLim here created a
% feedback loop: each call's headers nudged the axis limits down a bit,
% and the NEXT call read that already-lowered limit as its new baseline,
% sinking further every redraw. A value derived purely from the numeric
% data can never be influenced by where the header text itself was drawn
% last time.
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
        baseGap  = 0.015;   % axis -> closest (level 1) tier row
        rowStep  = 0.045;   % between-row spacing — confirmed good, keep as is
        for t = 1:(nTiers - 1)
            vals     = tierVals(:, t);
            level    = nTiers - t;   % outermost tier -> largest level -> furthest below axis
            % level*rowStep alone put even the CLOSEST row a full rowStep
            % below the axis before any interspacing applied, pushing the
            % whole group down — baseGap is the small, separate distance
            % from the axis to that first row; rowStep only spaces rows
            % from each other beyond it.
            yOff     = dataLo - (baseGap + (level - 1) * rowStep) * dataSpan;
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

function expandAxes = resolveExpandAxes(R, ptrBus)
% Pick EVERY Pointer axis to expand into its own nesting tier instead of
% averaging its multi-item selection away — every axis (by field order in
% R.ax{1}, excluding fold/perm) with a genuine multi-item Pointer
% selection, INCLUDING selecting every item ("select all" is not treated
% as equivalent to the untouched default here — a user selecting every
% item still wants to see them as separate bars, same as selecting
% all-but-one; collapsing only at exactly N of N produced a confusing
% off-by-one where removing a single item changed the chart's whole
% shape). With more than one qualifying axis, nexOp_barStatFromScores
% expands the full cartesian product across all of them — still a flat 1D
% bar chart with extra nested tiers, not a true 3D/"lego" chart (see
% WIP.md — that entry describes a genuinely different rendering problem,
% not this one).
%
%   R      : the (VW-filtered) RESULTS table — R.ax{1} gives this
%            result's axis fields
%   ptrBus : nexObj.collector.Pointer
%
%   expandAxes : string row vector, 0..K axis names, in field order
%                (outer tier first, matching the CTG convention)
    expandAxes = string.empty(1, 0);
    if height(R) == 0, return; end
    axFields = setdiff(fieldnames(R.ax{1}), {'fold', 'perm'}, 'stable');
    for k = 1:numel(axFields)
        f = axFields{k};
        if ~isfield(ptrBus.selections, f) || ~isfield(ptrBus.selKeys, f)
            continue;
        end
        selIdx = ptrBus.selections.(f);
        if numel(selIdx) > 1
            expandAxes(end+1) = string(f); %#ok<AGROW>
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
