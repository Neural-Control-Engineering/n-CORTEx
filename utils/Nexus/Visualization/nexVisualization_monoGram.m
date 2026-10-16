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
    % getCurrentSRC returns the RAW selKeys.SRC entry, which may carry the
    % "__W" weights-facet suffix applySRC/refreshSRC add — strip it for
    % every RESULTS lookup (RESULTS itself is keyed on the real result
    % ID, never the suffixed form). Which facet to actually pull is
    % nexObj.viewFacet, which applySRC already set correctly when SRC
    % last changed — reusing that instead of re-deriving it from the
    % suffix here keeps this in sync with Domain/Pointer's own facet by
    % construction, not by parallel logic that could drift out of step.
    srcKey  = erase(nexObj.getCurrentSRC(), "__W");
    viewSel = nex_returnSelectionMask(nexObj.collector.View);
    vwGroups = string(viewSel.VW);

    useResults = ~strcmp(srcKey, 'DF') ...
        && isfield(nexObj.RESULTS, srcKey) ...
        && ~isempty(nexObj.RESULTS.(srcKey)) ...
        && ~isequal(vwGroups, "") ...
        && ~isempty(vwGroups);

    if useResults
        RESULT = nexObj.RESULTS.(srcKey);
        matchingRows = nexObj.filterResultsByVW(RESULT, vwGroups);
        if isempty(matchingRows), return; end
        r = matchingRows(1);
        useW = isprop(nexObj, 'viewFacet') && strcmp(nexObj.viewFacet, "weights") ...
            && ismember('ax_W', string(RESULT.Properties.VariableNames)) ...
            && ~isempty(RESULT.W{r});
        if useW
            DF_src = struct('df', RESULT.W{r}, 'ax', RESULT.ax_W{r}, 'ptr', RESULT.ptr_W{r});
        else
            DF_src = struct('df', RESULT.df{r}, 'ax', RESULT.ax{r}, 'ptr', RESULT.ptr{r});
        end
    else
        DF_src = nexObj.DF_postOp;
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
    [Y, yTickLabels] = nexVis_axisToNumeric(ax_slice.(rowKey)(:));
    [X, xTickLabels] = nexVis_axisToNumeric(ax_slice.(colKey)(:)');
    if ptr.(rowKey).dim > ptr.(colKey).dim
        Z = Z';
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
    [Z, ~] = nexOp_applyComplexTransform(Z, [], component, scale);

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
        if rowClrAxID ~= ""
            [a, hit] = nex_axisColorFromRegistry(nexObj.nexon, rowClrAxID, ax_slice.(rowKey)(:));
            if hit, rowAnchor = a; end
        end
        if colClrAxID ~= ""
            [a, hit] = nex_axisColorFromRegistry(nexObj.nexon, colClrAxID, ax_slice.(colKey)(:));
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
    % ZData must match the edge grid (one larger than Z in each dim) —
    % padded by replicating the last row/col rather than NaN, since surf()
    % silently drops every face touching a NaN-coordinate vertex (would
    % clip the real last row/column of cells otherwise). CData, unlike
    % ZData, is accepted at the original (unpadded) per-cell size directly
    % — that's what actually produces the one-square-per-value rendering.
    canvas = nexObj.Figure.panel0.tiles.graphics.canvas;
    Zpadded = nexVis_padForSurfEdges(Z);
    if isempty(cdataRGB)
        set(canvas, "XData", Xedges, "YData", Yedges, "ZData", Zpadded, "CData", Z);
    else
        set(canvas, "XData", Xedges, "YData", Yedges, "ZData", Zpadded, "CData", cdataRGB);
    end

    %% Axis limits and labels
    ax = nexObj.Figure.panel0.tiles.ax;
    ax.ZLim = [zLim_low, zLim_high];

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
function [vals, labels] = nexVis_axisToNumeric(raw)
    if isnumeric(raw) || islogical(raw)
        vals   = double(raw);
        labels = string.empty;
    else
        vals   = 1:numel(raw);
        if iscolumn(raw), vals = vals'; end
        labels = string(raw);
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
