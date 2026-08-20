function nexVisualization_monoGram(nexObj, args)

    % CFG HEADER
    zLim_low  = args.zLim_low;   % default = -1
    zLim_high = args.zLim_high;  % default = 1
    cLim_low  = args.cLim_low;   % default = -11.5
    cLim_high = args.cLim_high;  % default = -9.5
    component = args.component;  % default = 'radial'
    scale     = args.scale;      % default = 'linear'
    fScale    = args.fScale;     % default = 'linear'

    % Guard
    if isempty(nexObj.DF_postOp) || isempty(nexObj.DF_postOp.df), return; end

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
    srcKey  = nexObj.getCurrentSRC();
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
        r     = matchingRows(1);
        DF_src = struct('df', RESULT.df{r}, 'ax', RESULT.ax{r}, 'ptr', RESULT.ptr{r});
    else
        DF_src = nexObj.DF_postOp;
    end

    %% Sync ptrBus → ptr.indices, then slice
    ptr = DF_src.ptr; 
    if isprop(nexObj, 'player') && ~isempty(nexObj.player) ...
            && strcmp(nexObj.player.Running, 'off')
        ptr = nexOp_syncPtrFromBus(ptr, nexObj.collector.Pointer);
    end
    [Z, ax_slice] = nexOp_sliceAndCollapse(DF_src, {rowKey, colKey});
    if ~ismatrix(Z), return; end  % residual axis wasn't collapsed; skip frame
    Y = double(ax_slice.(rowKey)(:));
    X = double(ax_slice.(colKey)(:)');
    if ptr.(rowKey).dim > ptr.(colKey).dim
        Z = Z';
    end
    [Z, ~] = nexOp_applyComplexTransform(Z, [], component, scale);

    %% Update canvas
    canvas = nexObj.Figure.panel0.tiles.graphics.canvas;
    set(canvas, "XData", X, "YData", Y, "ZData", Z, "CData", Z);

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

    % Guard degenerate axes: a display axis that is genuinely single-valued (e.g.
    % one channel) makes [v v] an invalid limit. For a LOG axis, drop non-positive
    % values first so a DC/0 frequency bin doesn't invalidate the limit. Only set
    % the limit when the axis actually spans; else leave it auto so it still draws.
    Yl = Y; if strcmp(ax.YScale, 'log'), Yl = Yl(Yl > 0); end
    Xl = X; if strcmp(ax.XScale, 'log'), Xl = Xl(Xl > 0); end
    if numel(Yl) >= 2 && max(Yl) > min(Yl), ax.YLim = [min(Yl), max(Yl)]; end
    if numel(Xl) >= 2 && max(Xl) > min(Xl), ax.XLim = [min(Xl), max(Xl)]; end
    clim(ax, [cLim_low, cLim_high]);

    xlabel(ax, char(colKey), 'Color', GREEN);
    ylabel(ax, char(rowKey), 'Color', GREEN);

    %% Title
    axTitle = nexTract_axisTitle(nexObj, nexObj.DF_postOp);
    title(ax, axTitle, "Color", GREEN);

    drawnow limitrate;
end
