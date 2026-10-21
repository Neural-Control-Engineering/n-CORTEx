function nexVisualization_monoGram(nexObj, args)

    % CFG HEADER
    zLim_low  = args.zLim_low;   % default = -1
    zLim_high = args.zLim_high;  % default = 1
    cLim_low  = args.cLim_low;   % default = -11.5
    cLim_high = args.cLim_high;  % default = -9.5
    component = args.component;  % default = 'radial'
    scale     = args.scale;      % default = 'linear'
    fScale    = args.fScale;     % default = 'linear'

    GREEN = nexObj.nexon.settings.Colors.cyberGreen;

    %% Domain axes from collector.Domain
    if isfield(nexObj.collector, 'Domain')
        domSel = nex_returnSelectionMask(nexObj.collector.Domain);
        d1Vals = string(domSel.D1);
    else
        d1Vals = nexObj.domain.D1;
    end
    if numel(d1Vals) < 2 || isequal(d1Vals(1), ""), return; end
    rowKey = d1Vals(1);
    colKey = d1Vals(2);

    %% Source selection (DF or RESULTS)
    % Resolution factored into nexObj.resolveActiveResultRow() so the
    % sigThreshold spinner's write-back callback (onSigThresholdChanged)
    % resolves the SAME row this render shows, instead of a second,
    % independently-maintained copy of this logic that could drift out of
    % sync with it. viewSel is still needed below (CLR), so kept here.
    viewSel = nex_returnSelectionMask(nexObj.collector.View);
    [useResults, RESULT, r, DF_src, ok] = nexObj.resolveActiveResultRow();
    if ~ok, return; end

    %% Significance-star overlay -- only meaningful when the active
    % RESULTS row carries a sigThreshold column (see DESIGN.md section 5's
    % deferred "DF-like basin with a keyword" idea; mdlObj_lme.fitAndReport
    % is the first producer of this column, but nothing here checks for
    % that class specifically -- any RESULTS table with the column gets
    % the same treatment). The spinner lives in the Vis panel
    % (nexFigure_monoGram.m) but is only ever meaningful for whichever row
    % is currently displayed, so its Visible/Value are pushed here on
    % every render, mirroring homeLimits()'s own "push value into spinner"
    % convention -- the spinner never writes anywhere on its own init.
    hasSigThreshold = useResults && ~isempty(RESULT) ...
        && ismember('sigThreshold', RESULT.Properties.VariableNames) ...
        && ~isnan(RESULT.sigThreshold(r));
    try
        sigEf = nexObj.Figure.panel_vis.editFields.sigThreshold;
        sigEf.Label.Visible   = hasSigThreshold;
        sigEf.uiField.Visible = hasSigThreshold;
        if hasSigThreshold
            sigEf.uiField.Value = RESULT.sigThreshold(r);
        end
    catch
    end

    % Guard — moved here (past DF_src resolution) from the top of the
    % function: it used to check nexObj.DF_postOp.df unconditionally,
    % before srcKey/useResults were even computed. That's correct for the
    % DF/DTS-router case but always empty for a source-watching nexObject
    % (nexObj_monoGram's mdlObj-sourced construction branch — DF_postOp
    % stays a placeholder forever there, real data lives in RESULTS/W),
    % so the old guard silently killed EVERY render regardless of SRC.
    if isempty(DF_src) || isempty(DF_src.df), return; end

    % Keep DF_postOp in sync with whatever's actually on screen — the
    % shared, unmodified stepAnimate/clearAnimatePointer (Play button,
    % common to every nexObject) read and write nexObj.DF_postOp.ax/.ptr
    % directly, expecting it to reflect the current view. For the plain
    % DF/DTS path DF_src already IS nexObj.DF_postOp (this is a no-op).
    % For a source-watching nexObject (RESULTS-backed), DF_src.ptr is the
    % SAME nexObj_ptr HANDLE object on every call — nex_initAxisPointer_v2
    % upgrades ptr to a handle specifically so pointer state survives a
    % surrounding struct being rebuilt (see its own tail comment), and
    % RESULT.ptr_W{r}/.ptr{r} is stored once in the table, never
    % reconstructed — so a stepAnimate write to
    % nexObj.DF_postOp.ptr.(axSel).value already mutates that shared
    % handle and is visible to the next call's freshly-resolved DF_src
    % with no extra carry-forward. This line is what wires stepAnimate's
    % READ side (nexObj.DF_postOp.ax, and the .ptr handle itself) up at
    % all for that path — domain.animate (the WHICH-axis half) is already
    % correctly kept live by onANIChanged, untouched here.
    nexObj.DF_postOp = DF_src;

    %% Sync ptrBus → ptr.indices, then slice
    ptr = DF_src.ptr;
    if isprop(nexObj, 'player') && ~isempty(nexObj.player) ...
            && strcmp(nexObj.player.Running, 'off')
        ptr = nexOp_syncPtrFromBus(ptr, nexObj.collector.Pointer);
    end
    [Z, ax_slice] = nexOp_sliceAndCollapse(DF_src, {rowKey, colKey});
    if ~ismatrix(Z), return; end  % residual axis wasn't collapsed; skip frame
    % double() on a non-numeric axis (string/categorical — e.g. a needsHR
    % block-PCA'd 'unit' axis, relabeled to region-name strings like "STN"
    % by nexOp_poolAxes/getBinEdges) silently yields NaN per element, not
    % an error — surf() then drops every NaN-coordinate face, rendering
    % nothing, while Z/C data (independent of X/Y) still looks completely
    % valid. Fall back to positional 1:n indices for a non-numeric axis;
    % tick labels below restore the real category names.
    [Y, yTickLabels, rowSortIdx] = nexVis_axisToNumeric(ax_slice.(rowKey)(:));
    [X, xTickLabels, colSortIdx] = nexVis_axisToNumeric(ax_slice.(colKey)(:)');
    % nexOp_sliceAndCollapse's own docstring promises display axes are
    % "never collapsed," but its terminal squeeze() can't tell a display
    % axis that's CURRENTLY width 1 (e.g. rowKey pinned to a single
    % range/index — a legitimate, if degenerate, 1-row grid) apart from a
    % residual axis legitimately mean-reduced to size 1 — squeeze() drops
    % both alike. Confirmed empirically: a 2-axis display with one axis
    % pinned to one value comes back as a plain 1-D vector (e.g. [3,1]),
    % silently losing the other axis's own dimension entirely, regardless
    % of which of rowKey/colKey it was. ax_slice.(rowKey)/.(colKey) still
    % correctly report their TRUE lengths even when 1 (Y/X above), so
    % repair by reshaping back to that known-correct shape whenever the
    % element count still matches — i.e. exactly the squeeze-ate-a-
    % singleton-display-dim case, never a genuinely different shape
    % problem (which this guard leaves alone to surface its own error).
    if numel(Z) == numel(Y) * numel(X) && ~isequal(size(Z), [numel(Y), numel(X)])
        Z = reshape(Z, [numel(Y), numel(X)]);
    end
    % rowKey/colKey's OWN ptr.(key).dim can be [] — a co-indexed metadata
    % label (nex_coIndexAxisLabels, e.g. "chans" riding on "feature"'s
    % real dimension, Nexus WIP.md #11) has no dimension of its own, and
    % comparing anything against [] (e.g. "1 > []") yields [] — which `if`
    % silently treats as false, skipping the transpose regardless of which
    % orientation Z actually needs. Resolve through the co-indexed sibling
    % (same registry nexVis_resolveClrAxis/resolveAxisDim already use for
    % this identical ambiguity) so the comparison has two REAL dims to
    % compare whenever one of the two display axes is metadata-only.
    rowDim = nexVis_resolveAxisDim(ptr, rowKey, DF_src.ax);
    colDim = nexVis_resolveAxisDim(ptr, colKey, DF_src.ax);
    if ~isempty(rowDim) && ~isempty(colDim) && rowDim > colDim
        Z = Z';
    end
    % Reorder Z to match whichever axis nexVis_axisToNumeric just
    % re-sorted numerically (see its own header comment) -- labels and
    % data must move together, so this is the matching dimension's
    % permutation, not a separate/independent re-sort.
    if ~isempty(rowSortIdx), Z = Z(rowSortIdx, :); end
    if ~isempty(colSortIdx), Z = Z(:, colSortIdx); end

    % Region-type axis (chans/dropout/map) depth-ordering (deep -> shallow
    % brain structure), same convention plot_bandHierarchyGrid.m's own
    % orderLevels uses, purely cosmetic -- confirmed directly that
    % monoGram's underlying per-region VALUES already match a reference
    % table exactly region-for-region; this only changes DISPLAY order so
    % it's easier to compare against that reference's own depth-ordered
    % layout. Gated on axis NAME (chans/dropout/map), not on
    % sigThreshold/mdlObj_lme -- applies equally to a raw PSD view over
    % chans/f/t with no significance facet involved at all. Only runs
    % when nexVis_axisToNumeric did NOT already reorder this axis
    % (rowSortIdx/colSortIdx still empty) -- a region axis's labels never
    % parse as numbers, so the two are mutually exclusive in practice, not
    % actually competing.
    if isempty(rowSortIdx)
        depthIdx = nexVis_regionDepthSortIdx(nexObj.nexon, rowKey, yTickLabels);
        if ~isempty(depthIdx)
            yTickLabels = yTickLabels(depthIdx);
            Z = Z(depthIdx, :);
        end
    end
    if isempty(colSortIdx)
        depthIdx = nexVis_regionDepthSortIdx(nexObj.nexon, colKey, xTickLabels);
        if ~isempty(depthIdx)
            xTickLabels = xTickLabels(depthIdx);
            Z = Z(:, depthIdx);
        end
    end
    % surf() treats X/Y as VERTEX positions and interpolates/facets the
    % space BETWEEN them — N tick values only ever produce N-1 rendered
    % cells, so e.g. 5 features draws as 4 squares, with the data visually
    % straddling gaps between its own axis ticks rather than sitting on
    % them. Fix without changing graphics object type: compute EDGES
    % (N+1 points, midpoint between each pair of centers, extrapolated at
    % the ends) for XData/YData instead of the centers themselves — this
    % is the standard pcolor-style "cell-centered" trick, still built on
    % plain surf(). X/Y (centers) are kept for tick placement below, so
    % labels still land in the middle of each cell.
    Xedges = nexVis_centersToEdges(X);
    Yedges = nexVis_centersToEdges(Y);
    % Captured BEFORE the component/scale transform below -- the
    % significance test compares against the real p-value, which
    % component/scale (meant for complex-valued signals, e.g. Hilbert
    % phase/magnitude) has no business altering.
    Zraw = Z;
    % Captured here, BEFORE either transform branch below -- max(Z, eps)
    % in the -log10 branch is MATLAB's two-argument element-wise max,
    % which silently returns the NON-NaN operand when one side is NaN
    % (documented behavior: max(NaN, eps) == eps, not NaN) -- so by the
    % time that branch finishes, every originally-NaN cell has quietly
    % become -log10(eps) =~ 15.65, a huge, spuriously "very significant"
    % value, with no NaN left to find afterward. Confirmed directly as
    % the cause of the black-forcing/Home-exclusion fixes below doing
    % nothing in log mode specifically (they rely on isnan(Z), checked
    % too late, after the laundering already happened). Capturing the
    % mask up front, before any transform, makes both fixes correct
    % regardless of which transform branch runs.
    nanMaskOrig = isnan(Z);
    if hasSigThreshold && strcmp(scale, 'log')
        % -log10(p) instead of nexOp_applyComplexTransform's generic log
        % behavior (meant for complex-valued signals, e.g. PSD magnitude)
        % -- same convention plot_bandHierarchyGrid.m already uses
        % (brighter = more significant). A plain log10(p) would go the
        % WRONG direction for this purpose: p in (0,1] makes log10(p)
        % NEGATIVE, growing MORE negative as p shrinks, the opposite of
        % "smaller p is more interesting." component is skipped entirely
        % here -- p-values are real-valued, not complex, so it has no
        % meaning for this data regardless of what's selected. eps floors
        % the rare p==0 cell so -log10 doesn't hit Inf.
        Z = -log10(max(Z, eps));
        Z(nanMaskOrig) = NaN;   % undo max(NaN,eps)'s own NaN-laundering above
    else
        [Z, ~] = nexOp_applyComplexTransform(Z, [], component, scale);
    end

    %% CLR — per-row/column/cell hue-gradient coloring, falling back to
    % the plain value-driven Z+clim colormap when CLR is empty or doesn't
    % resolve to a currently-displayed axis (rowKey/colKey). "ax--X" is
    % the standard CLR key convention (see nexObject collector.View / CLR
    % Bus docs) — X here must be rowKey or colKey to mean anything for a
    % 2-D surface (a CLR selection on some OTHER, currently-pinned axis
    % has no per-cell meaning here and is silently ignored, same as any
    % unresolvable CLR key elsewhere in this codebase).
    clrSel = string(viewSel.CLR);
    clrSel = clrSel(clrSel ~= "");
    cdataRGB = [];
    if ~isempty(clrSel)
        axClrCols  = clrSel(startsWith(clrSel, "ax--"));
        grpClrCols = clrSel(~startsWith(clrSel, "ax--"));
        clrAxNames = erase(axClrCols, "ax--");
        rowAnchor = []; colAnchor = [];
        % rowKey/colKey may not literally be in clrAxNames even when the
        % user picked the axis they mean — e.g. rowKey/colKey="unit" (the
        % field name actually present on a needsHR/W-facet DF) vs a CLR
        % selection of "chans" (the co-indexed sibling name the color
        % registry itself is keyed on — see nex_axisColorFromRegistry's
        % own 'chans' case comment). Resolve siblings via the same
        % registry nexOp_resolvePMapEntry already uses for the identical
        % ambiguity in pMap lookups, rather than a plain string match.
        rowClrAxID = nexVis_resolveClrAxis(rowKey, clrAxNames, DF_src.ax);
        colClrAxID = nexVis_resolveClrAxis(colKey, clrAxNames, DF_src.ax);
        % Use yTickLabels/xTickLabels, NOT ax_slice.(rowKey)/(colKey)
        % directly -- the latter are still in nexOp_sliceAndCollapse's
        % ORIGINAL axis order, while Y/X/Z (and yTickLabels/xTickLabels
        % themselves) may have since been numerically re-sorted (t) or
        % depth-reordered (chans/dropout/map) above. rowAnchor(ri,:) below
        % is indexed by the FINAL row position ri, so the label list this
        % resolves colors FROM must be in that same final order, or a
        % region's color ends up attached to the wrong row -- the exact
        % kind of label/data misalignment already fixed elsewhere this
        % session. Falls back to ax_slice directly only for a genuinely
        % numeric axis, where yTickLabels stays empty because no
        % reordering ever happens there anyway.
        rowAxVals = ax_slice.(rowKey)(:);
        if ~isempty(yTickLabels), rowAxVals = yTickLabels(:); end
        colAxVals = ax_slice.(colKey)(:);
        if ~isempty(xTickLabels), colAxVals = xTickLabels(:); end
        if rowClrAxID ~= ""
            [a, hit] = nex_axisColorFromRegistry(nexObj.nexon, rowClrAxID, rowAxVals);
            if hit, rowAnchor = a; end
        end
        if colClrAxID ~= ""
            [a, hit] = nex_axisColorFromRegistry(nexObj.nexon, colClrAxID, colAxVals);
            if hit, colAnchor = a; end
        end

        % Group-column CLR keys (e.g. "sessionLabel_phase") resolve to ONE
        % color for the currently-displayed RESULTS row — same
        % resolveGroupColors path every other nexObject's RESULTS-branch
        % rendering uses (bar, monoGraph). Not per-cell on their own
        % (there's exactly one row/trace on screen at a time here), but
        % blended into whatever per-row/col anchor the ax-- selections
        % above already produced, or used as a uniform base color on its
        % own when no ax-- axis is also selected.
        groupColor = [];
        if ~isempty(grpClrCols) && useResults
            try
                allColors  = nexObj.resolveGroupColors(RESULT, grpClrCols);
                groupColor = allColors(r, :);
            catch
            end
        end

        if ~isempty(rowAnchor) || ~isempty(colAnchor) || ~isempty(groupColor)
            anchorGrid = zeros(numel(Y), numel(X), 3);
            for ri = 1:numel(Y)
                for ci = 1:numel(X)
                    parts = {};
                    if ~isempty(rowAnchor),   parts{end+1} = rowAnchor(ri, :);   end %#ok<AGROW>
                    if ~isempty(colAnchor),   parts{end+1} = colAnchor(ci, :);   end %#ok<AGROW>
                    if ~isempty(groupColor),  parts{end+1} = groupColor;         end %#ok<AGROW>
                    anchorGrid(ri, ci, :) = nexVis_blendMany(parts);
                end
            end
            cdataRGB = nex_hueGradientCData(Z, anchorGrid, [cLim_low, cLim_high]);
        end
    end

    %% Update canvas
    ax     = nexObj.Figure.panel0.tiles.ax;
    canvas = nexObj.Figure.panel0.tiles.graphics.canvas;

    % Colormap gated on hasSigThreshold -- the saturated black->cyberGreen
    % ->white gradient (nexVis_sequentialColormap) is for p-value grids
    % specifically; every other source (plain DF/DTS, accuracy/weights
    % facets, ...) keeps the original cmap-cyberGreen.mat look
    % (nexVis_legacyCyberGreenColormap) rather than having it replaced
    % wholesale. Re-applied every render (cheap -- both are cached/
    % computed once) rather than only on SRC/VW change, so it always
    % matches whatever hasSigThreshold just resolved to for THIS frame.
    % Set BEFORE the truecolor conversion below, which reads this same
    % colormap back via colormap(ax) -- must already be current, not
    % whatever was left over from the previous render.
    if hasSigThreshold
        colormap(ax, nexVis_sequentialColormap(GREEN));
    else
        colormap(ax, nexVis_legacyCyberGreenColormap(nexObj.nexon));
    end

    % nanMaskOrig (captured earlier, before either transform branch) is
    % used below to (a) force these cells to pure black regardless of
    % cLim/colormap, and (b) let homeLimits() exclude them from its own
    % auto-scale (stashed on the canvas's UserData for it to read).
    %
    % surf() builds each cell's face from FOUR corner vertices shared with
    % its ROW/COLUMN NEIGHBORS (not just that cell's own value) -- so a
    % NaN cell doesn't just fail to render itself, it drops the rendered
    % face of every ADJACENT cell too, even when that neighbor has
    % perfectly valid data. Confirmed directly: depth-ordering places
    % "nst" (all-NaN, sparse region) immediately next to "STN" (valid
    % data), and STN's own cells vanished entirely as a result -- several
    % other regions adjacent to a sparse region in the depth-ordered list
    % are affected the same way. Replace NaN in the DISPLAY copy of Z
    % (never Zraw, which must keep seeing real NaN so the significance
    % test above continues to correctly skip those cells) with cLim_low,
    % so no face gets dropped due to a neighbor's missing data -- the
    % actual VALUE used here no longer matters for color (forced to black
    % below regardless), only that it's finite so the geometry renders.
    Z(nanMaskOrig) = cLim_low;

    % ZData must match the edge grid (one larger than Z in each dim) —
    % padded by replicating the last row/col rather than NaN, since surf()
    % silently drops every face touching a NaN-coordinate vertex (would
    % clip the real last row/column of cells otherwise). CData, unlike
    % ZData, is accepted at the original (unpadded) per-cell size directly
    % — that's what actually produces the one-square-per-value rendering.
    Zpadded = nexVis_padForSurfEdges(Z);

    % Force originally-NaN cells to pure black directly in the rendered
    % color -- independent of cLim/colormap, unlike "set Z to cLim_low"
    % alone, which only reads as black for as long as cLim_low happens to
    % still be the bottom of whatever color range is active; it breaks
    % the moment cLim gets rescaled afterward on its own (e.g. Home
    % auto-fitting to a different range once scale='log' changes the
    % data's own units -- confirmed directly as the cause of "those
    % garbage bands now read white"). Requires a truecolor (RGB) CData --
    % surf can't mix a scalar+colormap cell with a literal-color cell in
    % the same CData -- so build one from the current colormap by hand
    % whenever no CLR-driven cdataRGB already exists, then overwrite the
    % masked cells on top of either.
    if any(nanMaskOrig(:))
        if isempty(cdataRGB)
            cmapNow = colormap(ax);
            nColors = size(cmapNow, 1);
            idx = round((Z - cLim_low) / max(cLim_high - cLim_low, eps) * (nColors - 1)) + 1;
            idx = min(max(idx, 1), nColors);
            cdataRGB = reshape(cmapNow(idx(:), :), [size(Z), 3]);
        end
        cdataRGB(repmat(nanMaskOrig, [1, 1, 3])) = 0;
    end

    if isempty(cdataRGB)
        set(canvas, "XData", Xedges, "YData", Yedges, "ZData", Zpadded, "CData", Z);
    else
        set(canvas, "XData", Xedges, "YData", Yedges, "ZData", Zpadded, "CData", cdataRGB);
    end

    % Stash the NaN mask (padded to match ZData's own shape) on the
    % canvas so homeLimits() can exclude these patched/garbage cells from
    % its own min/max auto-scale -- without this, Home fits zLim/cLim to
    % include cLim_low itself (the patch value), dragging the scale toward
    % whatever cLim_low happened to be at patch time instead of the real
    % data's own range (confirmed directly as the cause of "Home scales
    % badly, fitting those garbage entries").
    canvas.UserData = nexVis_padForSurfEdges(nanMaskOrig);

    %% Axis limits and labels
    ax.ZLim = [zLim_low, zLim_high];

    %% Significance stars -- one '*' per cell where Zraw (the real,
    % untransformed value -- see its own capture comment above) crosses
    % the active threshold. Old stars are deleted and redrawn each call
    % (their count changes with the threshold/cell, unlike canvas's fixed-
    % size ZData/CData, which is updated in place instead) rather than
    % reused. Placed on a flat plane just above zLim_high -- not at each
    % cell's own surface height -- so every star stays visible regardless
    % of the surface's own shape or the current camera angle (monoGram is
    % a real 3-D surf, not a top-down-only view).
    try
        oldStars = nexObj.Figure.panel0.tiles.graphics.sigStars;
        delete(oldStars(isgraphics(oldStars)));
    catch
    end
    if hasSigThreshold
        sigMask = Zraw < RESULT.sigThreshold(r);
        [sigRowIdx, sigColIdx] = find(sigMask);
        starHandles = gobjects(numel(sigRowIdx), 1);
        zStar = zLim_high + 0.05 * (zLim_high - zLim_low);
        % Star color flips with the same scale='log' gate that flips
        % which end of the colormap "more significant" sits at: linear
        % mode keeps the raw p-value, where smaller (more significant) is
        % CLOSER TO cLim_low -- the dark end -- so a white star stands out
        % against it. -log10(p) (log mode) inverts that: smaller p is a
        % LARGER value, pushing significant cells toward cLim_high -- the
        % bright/white end -- where a white star disappears. Confirmed
        % directly as the cause of stars vanishing in log mode.
        if strcmp(scale, 'log')
            starColor = 'k';
        else
            starColor = 'w';
        end
        for si = 1:numel(sigRowIdx)
            starHandles(si) = text(ax, X(sigColIdx(si)), Y(sigRowIdx(si)), zStar, '*', ...
                'Color', starColor, 'FontWeight', 'bold', 'FontSize', 25, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        end
        nexObj.Figure.panel0.tiles.graphics.sigStars = starHandles;
    else
        nexObj.Figure.panel0.tiles.graphics.sigStars = gobjects(0, 1);
    end

    % Frequency-axis scale (log/linear) — applied only to whichever DISPLAYED
    % axis is 'f' (rowKey→Y, colKey→X); the other axis stays linear. No-op when
    % 'f' isn't displayed.
    ax.XScale = 'linear';  ax.YScale = 'linear';
    if     strcmp(rowKey, "f"), ax.YScale = char(fScale);
    elseif strcmp(colKey, "f"), ax.XScale = char(fScale);
    end

    % Guard degenerate axes. Uses edges, not centers, so the full outer
    % cell is shown rather than clipped at its center point — and a
    % genuinely single-valued axis (one channel) is no longer degenerate
    % here either, since even one center still produces two edges. For a
    % LOG axis, drop non-positive values first so a DC/0 frequency bin
    % doesn't invalidate the limit. Only set the limit when the axis
    % actually spans; else leave it auto so it still draws.
    Yl = Yedges; if strcmp(ax.YScale, 'log'), Yl = Yl(Yl > 0); end
    Xl = Xedges; if strcmp(ax.XScale, 'log'), Xl = Xl(Xl > 0); end
    if numel(Yl) >= 2 && max(Yl) > min(Yl), ax.YLim = [min(Yl), max(Yl)]; end
    if numel(Xl) >= 2 && max(Xl) > min(Xl), ax.XLim = [min(Xl), max(Xl)]; end
    clim(ax, [cLim_low, cLim_high]);

    % Restore real category names as tick labels on a non-numeric axis
    % (positional 1:n was only ever a plotting coordinate — see
    % nexVis_axisToNumeric). Numeric axes (the common case) get [] back
    % and MATLAB's own auto ticks apply unchanged.
    if ~isempty(yTickLabels)
        ax.YTick = Y;  ax.YTickLabel = cellstr(yTickLabels);
    else
        ax.YTickLabelMode = 'auto';  ax.YTickMode = 'auto';
    end
    if ~isempty(xTickLabels)
        ax.XTick = X;  ax.XTickLabel = cellstr(xTickLabels);
    else
        ax.XTickLabelMode = 'auto';  ax.XTickMode = 'auto';
    end

    xlabel(ax, char(colKey), 'Color', GREEN);
    ylabel(ax, char(rowKey), 'Color', GREEN);

    %% Title
    % Explicit dimList — every DF_src.ax field except the two just plotted
    % (rowKey/colKey already have their own axis labels above) — rather
    % than relying on nexTract_axisTitle's default (nexObj.domain.D2).
    % monoGram's own D1 is a caller-picked PAIR of display axes via
    % collector.Domain (see the class header), not the base nexObject
    % D1/D2 convention (D2 = single primary/training axis) domain.D2 was
    % ever meant to track — and for a source-watching nexObject (this
    % class's mdlObj-sourced construction branch), nexObj.domain is never
    % populated with D1/D2 at all, so the default crashed outright rather
    % than merely showing the wrong thing. This also shows every pinned
    % axis (fold, perm, any SWP axis) instead of whatever single axis
    % domain.D2 happened to hold, which is more informative regardless of
    % source.
    axFields = string(fieldnames(DF_src.ax))';
    pinnedAx = axFields(~ismember(axFields, [rowKey, colKey, "latent"]));
    axTitle  = nexTract_axisTitle(nexObj, DF_src, pinnedAx);
    title(ax, axTitle, "Color", GREEN);

    drawnow limitrate;
end

% ── N tick centers → N+1 cell edges ───────────────────────────────────────
% Midpoint between each pair of adjacent centers; the two outer edges are
% extrapolated symmetrically from the nearest midpoint. Orientation
% (row/column) of the input is preserved. A single center (or none) has no
% neighbor to infer spacing from, so falls back to a fixed unit width.
function edges = nexVis_centersToEdges(centers)
    wasRow = isrow(centers);
    c = centers(:);
    n = numel(c);
    if n <= 1
        if isempty(c)
            e = [0; 1];
        else
            e = [c - 0.5; c + 0.5];
        end
    else
        mids      = (c(1:end-1) + c(2:end)) / 2;
        firstEdge = c(1) - (mids(1) - c(1));
        lastEdge  = c(end) + (c(end) - mids(end));
        e = [firstEdge; mids; lastEdge];
    end
    if wasRow, edges = e'; else, edges = e; end
end

% ── Pad Z by replicating its last row/column ──────────────────────────────
% surf()'s ZData must match the (M+1)x(N+1) edge grid one larger than Z in
% each dimension. NaN padding would make surf() drop every face touching
% that edge vertex (see nexVis_axisToNumeric's own comment on this) — that
% would clip the real last row/column of cells rather than just adding an
% unused edge, so replication is used instead of NaN.
function Zp = nexVis_padForSurfEdges(Z)
    Zp = Z(:, [1:end, end]);
    Zp = Zp([1:end, end], :);
end

% ── Non-numeric axis → positional coordinate + tick labels ──────────────────
% surf() needs real numeric X/Y; a label-type axis (string/categorical/
% cellstr — e.g. needsHR's region-pooled 'unit' values) has no natural
% numeric position of its own, unlike a genuine physical axis (f, t, chans
% on an LFP DF). double() on those silently returns NaN per element rather
% than erroring, which is what made this fail quietly.
function [vals, labels, sortIdx] = nexVis_axisToNumeric(raw)
% sortIdx (3rd output): empty unless raw is a non-numeric axis whose
% labels ALL parse cleanly as numbers (e.g. buildLongSTAT's "t" axis,
% stored as string-wrapped categorical for grid-cell matching) --
% categorical()'s own default category order is lexicographic-string
% ("-1.033" sorts before "-2.033" wrongly, same as "-0.3" before "-1.3"
% before "-2.3"), the same bug plot_bandHierarchyGrid.m's own orderLevels
% already patches for ITS OWN display. vals stays plain 1:numel(raw)
% either way (this is the positional-fallback branch), so what actually
% changes is which LABEL lands at each position -- the caller MUST permute
% the matching dimension of Z by sortIdx too, or labels and data drift
% apart (labels alone would just relabel without moving the data,
% reproducing the exact kind of silent label/data misalignment this
% session already hunted down once in buildLongSTAT.m).
    sortIdx = [];
    if isnumeric(raw) || islogical(raw)
        vals   = double(raw);
        labels = string.empty;
    else
        strs = string(raw);
        vals = 1:numel(raw);
        if iscolumn(raw), vals = vals'; end
        numericVals = str2double(strs);
        if ~isempty(numericVals) && ~any(isnan(numericVals))
            [~, sortIdx] = sort(numericVals(:));
            if isrow(raw), sortIdx = sortIdx'; end
            labels = strs(sortIdx);
        else
            labels = strs;
        end
    end
end

% ── Region-type axis depth-ordering (deep -> shallow brain structure) ───
% Same axis-name check and nexOp_regionDepthOrder call
% plot_bandHierarchyGrid.m's own orderLevels uses -- purely a DISPLAY
% convenience, not a correctness fix (confirmed directly: underlying
% per-region values already match a reference table exactly without
% this). Gated on axis NAME only (chans/dropout/map, after stripping a
% leading "region"), never on sigThreshold/mdlObj_lme -- applies equally
% to a raw PSD view over chans/f/t with no significance facet at all.
function sortIdx = nexVis_regionDepthSortIdx(nexon, axisName, labels)
    sortIdx = [];
    if isempty(nexon) || isempty(labels), return; end
    axID = regexprep(lower(axisName), '^region', '');
    if ~ismember(axID, ["dropout", "chans", "map"]), return; end
    try
        ordered = nexOp_regionDepthOrder(nexon, labels);
        if isequal(string(ordered), string(labels))
            return;   % no registry match -- same no-op fallback
                      % plot_bandHierarchyGrid.m's orderLevels uses
        end
        [found, idx] = ismember(string(ordered), string(labels));
        if ~all(found), sortIdx = []; return; end
        sortIdx = idx;
        if isrow(labels), sortIdx = sortIdx(:)'; else, sortIdx = sortIdx(:); end
    catch
    end
end

% ── Resolve a displayed axis name to a matching CLR selection, checking ──
% co-indexed siblings (e.g. chans/unit) via the same nexOp_coIndexPairs
% registry nexOp_resolvePMapEntry already uses for the identical ambiguity
% in pMap lookups — a plain string match misses this whenever the
% displayed axis's own field name differs from the one the color registry
% (or the user) is keyed on. Returns the matched CLR axis name (which may
% differ from `key`) to pass into nex_axisColorFromRegistry, or "" if
% neither key nor any of its co-indexed siblings is in clrAxNames.
function matchedAxID = nexVis_resolveClrAxis(key, clrAxNames, ax)
    matchedAxID = "";
    if ismember(key, clrAxNames)
        matchedAxID = key;
        return;
    end
    pairs = nexOp_coIndexPairs(ax);
    for p = 1:numel(pairs)
        pair = string(pairs{p});
        if ~ismember(key, pair), continue; end
        sib = pair(pair ~= key);
        if ~isempty(sib) && ismember(sib(1), clrAxNames)
            matchedAxID = sib(1);
            return;
        end
    end
end

% ── Resolve a display axis's EFFECTIVE dim for the Z-orientation check ───
% ptr.(key).dim is [] for a co-indexed metadata-label axis (e.g. "chans"
% riding on "feature"'s real dimension — nex_coIndexAxisLabels) — it has
% no dimension of its own, by design, so fall back to whichever
% co-indexed sibling DOES own one. Returns [] only if neither key nor any
% sibling resolves to a real dimension.
function d = nexVis_resolveAxisDim(ptr, key, ax)
    d = [];
    if isfield(ptr, key) && isfield(ptr.(key), 'dim') && ~isempty(ptr.(key).dim)
        d = ptr.(key).dim;
        return;
    end
    pairs = nexOp_coIndexPairs(ax);
    for p = 1:numel(pairs)
        pair = string(pairs{p});
        if ~ismember(key, pair), continue; end
        sib = pair(pair ~= key);
        if ~isempty(sib) && isfield(ptr, sib(1)) && isfield(ptr.(sib(1)), 'dim') ...
                && ~isempty(ptr.(sib(1)).dim)
            d = ptr.(sib(1)).dim;
            return;
        end
    end
end

% ── Hue-circular-mean blend of N anchor colors ────────────────────────────
% Same idiom nexOp_resolveGroupColors.m's blendCrossLabel already uses for
% "A-×-B" cross-comparison labels, generalized from 2 colors to however
% many contributed to one cell (row anchor, column anchor, group color —
% any subset). Kept as a small local copy here rather than factored out,
% since this is the only other call site and the inputs differ (named LUT
% labels there, resolved RGB anchors here).
function rgb = nexVis_blendMany(colorList)
    if isempty(colorList)
        rgb = [1 1 1];
        return;
    end
    if isscalar(colorList)
        rgb = colorList{1};
        return;
    end
    C = cat(1, colorList{:});
    hsvAll = rgb2hsv(C);
    angles = hsvAll(:, 1) * 2 * pi;
    hue = mod(atan2(mean(sin(angles)), mean(cos(angles))) / (2 * pi), 1);
    rgb = hsv2rgb([hue, mean(hsvAll(:, 2)), mean(hsvAll(:, 3))]);
end
