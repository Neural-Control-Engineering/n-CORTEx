function nexVisualization_violin(nexObj, args) %#ok<INUSD>
% Render the active SRC result's T_long (one combo's raw trial-level long
% table, or the ctg-sourced "live" compile) as a set of violin groups into
% nexObj's canvas. CTG-selected columns + multi-select Pointer axes
% ("expand axes") split T_long into groups -- the SAME nexStat_binSTAT +
% expand-axis mechanism nexVisualization_bar.m uses for bars (see that
% file's own header and resolveExpandAxes), just drawing a
% KDE+scatter+error group per resulting position instead of one bar
% height. CLR resolves per-group color via the shared resolveGroupColors
% machinery, same as every other nexObject.
%
% VW selects WHICH RESULTS ROW (combo) to draw -- unlike nexObj_bar, which
% overlays every VW-selected row as bars side by side, this draws only
% ONE row's T_long at a time (the last VW-selected row): overlaying raw
% trial-level points from two different combos/strata on one axis would
% be visually incoherent (different strata's trials aren't the same
% population, unlike bar's already-aggregated scores).
%
% Persistent handles: a GROWABLE array (Figure.violinPlot.handles), one
% {patch, scatter, errbar} triple per violin slot -- unlike nexObj_bar's
% single Bar object (which natively represents a whole group of bars),
% each violin needs its own patch, so the array grows/shrinks-by-hiding
% as the group count changes between calls. Same "array of handles,
% delete/hide stale ones" idea nexVisualization_bar.m already uses for
% its tier-header text() objects (updateTierHeaders), applied here to the
% violins themselves instead of just the labels.
%
% Significance encoding (DESIGN.md section 2's global-vs-per-unit split)
% is NOT implemented in this first pass -- T_long carries only raw
% per-trial values, not p-values (those live in the PARALLEL df/ax facet
% of the same RESULTS row, which nexObj_monoGram visualizes). Annotating
% a specific violin/group as significant would need cross-referencing
% that facet for the Pointer's currently-collapsed grid cell + a chosen
% mdlStep -- a real follow-up, deliberately deferred until the basic
% rendering is confirmed working.

    GREEN = resolveGreen(nexObj);
    ax    = nexObj.Figure.panel0.tiles.ax;

    bus = nexObj.collector.View;
    srcSel = bus.selections.SRC;
    if isempty(srcSel) || isempty(bus.selKeys.SRC)
        fprintf('[nexVisualization_violin] bail: no SRC selection.\n');
        clearViolins(nexObj); return;
    end
    srcKey = char(bus.selKeys.SRC(min(srcSel(end), numel(bus.selKeys.SRC))));
    if ~isfield(nexObj.RESULTS, srcKey)
        fprintf('[nexVisualization_violin] bail: RESULTS has no field "%s".\n', srcKey);
        clearViolins(nexObj); return;
    end
    R = nexObj.RESULTS.(srcKey);
    if ~istable(R) || height(R) == 0 || ~ismember('T_long', R.Properties.VariableNames)
        fprintf('[nexVisualization_violin] bail: RESULTS.%s is not a non-empty table with a T_long column (istable=%d, height=%d).\n', ...
            srcKey, istable(R), heightOrZero(R));
        clearViolins(nexObj); return;
    end

    % VW row filter -- which combo's T_long to draw (last selected).
    vwSel = bus.selections.VW;
    if isempty(vwSel) || isempty(bus.selKeys.VW)
        rowIdx = 1;
    else
        vwSel  = vwSel(vwSel >= 1 & vwSel <= numel(bus.selKeys.VW));
        rowIdx = min(max(1, vwSel(end)), height(R));
    end
    T = R.T_long{rowIdx};
    if ~istable(T) || height(T) == 0
        fprintf('[nexVisualization_violin] bail: R.T_long{%d} is not a non-empty table (istable=%d, height=%d).\n', ...
            rowIdx, istable(T), heightOrZero(T));
        clearViolins(nexObj); return;
    end
    fprintf('[nexVisualization_violin] T_long{%d}: %d rows before any Pointer filtering.\n', rowIdx, height(T));

    % CTG grouping columns (outer tier first, per selection order).
    ctgSel  = bus.selections.CTG;
    ctgCols = string.empty;
    if ~isempty(ctgSel) && ~isempty(bus.selKeys.CTG)
        ctgSel  = ctgSel(ctgSel >= 1 & ctgSel <= numel(bus.selKeys.CTG));
        ctgCols = string(bus.selKeys.CTG(ctgSel));
    end

    ptrBus = nexObj.collector.Pointer;

    % Pointer filtering and CTG grouping are ORTHOGONAL -- filter EVERY
    % axis (CTG columns included) down to its current Pointer selection
    % FIRST, then group whatever survives by the CTG columns. Previously
    % CTG columns were excluded from this filter entirely (grouping
    % always used every distinct value present in T, ignoring any Pointer
    % narrowing on that same axis) -- confirmed directly: picking one
    % specific chans region via the Pointer panel while chans was also a
    % CTG column still showed every OTHER region and not the one actually
    % selected, because the filter never ran for it. "CTG = which columns
    % to nest violins by" and "Pointer = which values of ANY axis to
    % include" need to both apply, not fight for the same column.
    collapseAx = setdiff(string(T.Properties.VariableNames), "df", 'stable');
    for k = 1:numel(collapseAx)
        f = char(collapseAx(k));
        if ~isfield(ptrBus.selections, f) || ~isfield(ptrBus.selKeys, f), continue; end
        selIdx = ptrBus.selections.(f);
        if isempty(selIdx), continue; end
        allVals = ptrBus.selKeys.(f);
        selVals = allVals(selIdx);
        if iscategorical(T.(f))
            keep = ismember(string(T.(f)), string(selVals));
        else
            keep = ismember(T.(f), selVals);
        end
        T = T(keep, :);
    end
    if height(T) == 0
        clearViolins(nexObj); return;
    end

    groupCols = ctgCols;
    % Group assignment -- nexStat_binSTAT's own X positions (same
    % mechanism nexVisualization_bar.m uses for bar/tier positions),
    % reused here as violin slot positions instead.
    if isempty(groupCols)
        X = ones(height(T), 1);
    else
        X = nexStat_binSTAT(T, groupCols);
    end
    [Xu, ~, grpIdx] = unique(X);
    nGroups   = numel(Xu);
    groupRows = arrayfun(@(g) find(grpIdx == g), (1:nGroups)', 'UniformOutput', false);
    fprintf('[nexVisualization_violin] %d rows survived filtering -> grouped by [%s] into %d group(s).\n', ...
        height(T), strjoin(groupCols, ','), nGroups);

    % Per-group color -- resolveGroupColors needs one representative row
    % per group (same two-pass LUT/atlas/HSV resolution every other
    % nexObject's RESULTS-branch rendering uses).
    clrSel  = bus.selections.CLR;
    clrCols = string.empty;
    if ~isempty(clrSel) && ~isempty(bus.selKeys.CLR)
        clrSel  = clrSel(clrSel >= 1 & clrSel <= numel(bus.selKeys.CLR));
        clrCols = string(bus.selKeys.CLR(clrSel));
    end
    if ~isempty(clrCols)
        repRows = cellfun(@(idx) idx(1), groupRows);
        colors  = nexObj.resolveGroupColors(T(repRows, :), clrCols);
    elseif nGroups > 1
        colors = nexVis_hsvSpread(nGroups);
    else
        colors = GREEN;
    end

    hV = ensureViolinHandles(nexObj, ax, nGroups);
    maxHalfWidth = 0.35;
    nTiers   = numel(groupCols);
    tierVals = strings(nGroups, nTiers);
    allData  = cell(nGroups, 1);
    for g = 1:nGroups
        data = T.df(groupRows{g});
        data = data(~isnan(data));
        allData{g} = data;
        xc   = Xu(g);
        c    = colors(min(g, size(colors, 1)), :);

        if numel(data) >= 2 && numel(unique(data)) > 1
            [f_, xi_] = ksdensity(data);
            f_ = f_ / max(f_) * maxHalfWidth;
            set(hV(g).patch, 'XData', [xc + f_, fliplr(xc - f_)], ...
                'YData', [xi_, fliplr(xi_)], 'FaceColor', c, 'FaceAlpha', 0.5, ...
                'EdgeColor', c, 'Visible', 'on');
        else
            set(hV(g).patch, 'Visible', 'off');
        end

        jitter = (rand(numel(data), 1) - 0.5) * maxHalfWidth * 0.6;
        set(hV(g).scatter, 'XData', xc + jitter, 'YData', data, ...
            'CData', repmat(c, max(numel(data),1), 1), 'Visible', 'on');

        mu = mean(data, 'omitnan');
        se = std(data, 'omitnan') / sqrt(max(1, numel(data)));
        set(hV(g).errbar, 'XData', xc, 'YData', mu, ...
            'YNegativeDelta', se, 'YPositiveDelta', se, 'Visible', 'on', ...
            'Color', GREEN, 'LineWidth', 2, 'CapSize', 6);

        r0 = groupRows{g}(1);
        for t = 1:nTiers
            tierVals(g, t) = string(T.(char(groupCols(t)))(r0));
        end
    end
    % Hide any leftover handles beyond nGroups (stale from a previous,
    % larger selection) -- same "hide the rest" idea as nexVisualization_bar
    % applies to its own handle set via setVisible.
    for g = nGroups+1:numel(hV)
        set(hV(g).patch,   'Visible', 'off');
        set(hV(g).scatter, 'Visible', 'off');
        set(hV(g).errbar,  'Visible', 'off');
    end

    % Innermost tier (last CTG column, or a bare index when ungrouped)
    % drives the axis's own XTickLabel, one label per violin -- every
    % OUTER tier is rendered as a true nested group header below the
    % axis instead (updateTierHeadersViolin), same split
    % nexVisualization_bar.m uses for its own nested bars (see
    % updateTierHeaders there): CTG selection order (outer tier first)
    % is what controls nesting direction -- e.g. picking "chans" before
    % "sessionLabel_subj" nests subject within each region; reversing
    % that selection order nests region within each subject instead. No
    % separate flip property needed (unlike nexVisualization_bar's
    % reverseExpandOrder, which exists for a different, Pointer-driven
    % tier this class never has).
    ax.XTick = Xu;
    if nTiers > 0
        ax.XTickLabel = cellstr(tierVals(:, end));
    else
        ax.XTickLabel = {};
    end
    ylabel(ax, 'df', 'Color', GREEN);
    title(ax, sprintf('%s  (row %d/%d)', srcKey, rowIdx, height(R)), ...
          'Color', GREEN, 'FontWeight', 'normal', 'FontSize', 9, 'Interpreter', 'none');

    % Baseline for stacked tier-header text, from the actual plotted
    % data range (violin KDE + scatter + error bars) -- same "derive from
    % data, never from ax.YLim" reasoning as nexVisualization_bar's own
    % updateTierHeaders (reading YLim back would create a feedback loop:
    % header text nudges auto-YLim down, next call reads that as its new,
    % lower baseline, sinking further every redraw).
    allVals  = vertcat(allData{:});
    dataLo   = min(allVals, [], 'omitnan');
    dataHi   = max(allVals, [], 'omitnan');
    if isempty(dataLo) || isnan(dataLo), dataLo = 0; dataHi = 1; end
    dataSpan = max(dataHi - dataLo, eps);
    updateTierHeadersViolin(nexObj, ax, Xu, tierVals, GREEN, dataLo, dataSpan);
end


function updateTierHeadersViolin(nexObj, ax, Xu, tierVals, GREEN, dataLo, dataSpan)
% Draw one text() label per contiguous run of violins sharing an OUTER
% tier's value -- direct port of nexVisualization_bar.m's own
% updateTierHeaders to violin's geometry (Xu/dataLo/dataSpan instead of
% bar's Xs/baseline, no null-band term). Every column of tierVals except
% the last (the innermost tier, already shown via the axis's own
% XTickLabel) gets its own stacked row of headers, outermost tier
% furthest below the axis. Xu/tierVals are already in ascending-X order
% (Xu comes from unique(), which sorts; tierVals was built group-by-group
% in that same order), so a "contiguous run" here really is one visually
% adjacent cluster -- no separate sort step needed, unlike bar's own
% version (whose per-ROW X isn't pre-sorted).
%
% Handles are deleted and recreated every call (same as bar's version) --
% the number of runs varies with the data/selection, no fixed slot to
% update, and this set is small relative to everything else per call.
    if isfield(nexObj.Figure, 'violinPlot') && isfield(nexObj.Figure.violinPlot, 'tierLabels')
        old = nexObj.Figure.violinPlot.tierLabels;
        for i = 1:numel(old)
            if isvalid(old(i)), delete(old(i)); end
        end
    end
    handles = gobjects(0);
    nTiers  = size(tierVals, 2);
    if nTiers > 1 && ~isempty(Xu)
        try
            ax.Clipping = 'off';
        catch
        end
        baseGap = 0.015;   % axis -> closest (level 1) tier row
        rowStep = 0.045;   % between-row spacing, matching bar's own values
        for t = 1:(nTiers - 1)
            vals     = tierVals(:, t);
            level    = nTiers - t;   % outermost tier -> largest level -> furthest below axis
            yOff     = dataLo - (baseGap + (level - 1) * rowStep) * dataSpan;
            changeAt = find(vals(2:end) ~= vals(1:end-1));
            runStart = [1; changeAt + 1];
            runEnd   = [changeAt; numel(vals)];
            for r = 1:numel(runStart)
                xc = mean(Xu(runStart(r):runEnd(r)));
                h  = text(ax, xc, yOff, char(vals(runStart(r))), ...
                          'Color', GREEN, 'FontSize', 9, ...
                          'HorizontalAlignment', 'center', 'Clipping', 'off');
                handles(end+1) = h; %#ok<AGROW>
            end
        end
    end
    nexObj.Figure.violinPlot.tierLabels = handles;
end

function hV = ensureViolinHandles(nexObj, ax, nNeeded)
% Lazily create/grow the persistent {patch,scatter,errbar} handle array.
% Existing handles are updated in place (set(...)); new ones are created
% only when nNeeded exceeds what already exists. A first-element validity
% check (same idea nexVisualization_bar.ensureBarHandles uses) catches a
% stale set left over from an axes that was cleared/recreated elsewhere.
    if ~isfield(nexObj.Figure, 'violinPlot') || ~isstruct(nexObj.Figure.violinPlot) ...
            || ~isfield(nexObj.Figure.violinPlot, 'handles')
        nexObj.Figure.violinPlot.handles = struct('patch', {}, 'scatter', {}, 'errbar', {});
    end
    existing  = nexObj.Figure.violinPlot.handles;
    nExisting = numel(existing);
    if nExisting > 0 && ~isvalid(existing(1).patch)
        existing  = struct('patch', {}, 'scatter', {}, 'errbar', {});
        nExisting = 0;
    end
    for g = (nExisting + 1):nNeeded
        existing(g).patch   = fill(ax, nan, nan, [0.24 0.94 0.46], ...
            'FaceAlpha', 0.5, 'EdgeColor', [0.24 0.94 0.46], 'Visible', 'off');
        existing(g).scatter = scatter(ax, nan, nan, 40, [0 0 0], 'filled', ...
            'MarkerFaceAlpha', 0.5, 'Visible', 'off');
        existing(g).errbar  = errorbar(ax, nan, nan, nan, 'LineStyle', 'none', ...
            'LineWidth', 2, 'CapSize', 6, 'Visible', 'off');
    end
    nexObj.Figure.violinPlot.handles = existing;
    hV = existing;
end

function clearViolins(nexObj)
    if ~isfield(nexObj.Figure, 'violinPlot') || ~isstruct(nexObj.Figure.violinPlot) ...
            || ~isfield(nexObj.Figure.violinPlot, 'handles')
        return;
    end
    h = nexObj.Figure.violinPlot.handles;
    for g = 1:numel(h)
        if isvalid(h(g).patch),   h(g).patch.Visible   = 'off'; end
        if isvalid(h(g).scatter), h(g).scatter.Visible = 'off'; end
        if isvalid(h(g).errbar),  h(g).errbar.Visible  = 'off'; end
    end
    if isfield(nexObj.Figure.violinPlot, 'tierLabels')
        tl = nexObj.Figure.violinPlot.tierLabels;
        for i = 1:numel(tl)
            if isvalid(tl(i)), tl(i).Visible = 'off'; end
        end
    end
end

function h = heightOrZero(x)
% height() errors outright on a non-table/non-array (e.g. [] or a struct)
% -- this diagnostic-only helper just needs SOME number to print.
    try
        h = height(x);
    catch
        h = 0;
    end
end

function GREEN = resolveGreen(nexObj)
    try
        GREEN = nexObj.nexon.settings.Colors.cyberGreen;
    catch
        GREEN = [0.18 0.8 0.44];
    end
end
