function nexVisualization_monoGram(nexObj, args)

    % CFG HEADER    
    zLim_low  = args.zLim_low;  % default = -1
    zLim_high = args.zLim_high; % default = 1
    cLim_low = args.cLim_low; % default = -11.5
    cLim_high = args.cLim_high; % default = -9.5

    %% Slice DF using D1 — primary display axes (complement of D2)
    rowKey = nexObj.domain.D1(1);
    rowRange = nexObj.DF_postOp.ptr.(rowKey).range;
    colKey = nexObj.domain.D1(2);
    colRange = nexObj.DF_postOp.ptr.(colKey).range;
    ptr    = nexObj.DF_postOp.ptr;
    Y = nexObj.DF_postOp.ax.(rowKey);
    Y = Y(rowRange(1):rowRange(end));
    X = nexObj.DF_postOp.ax.(colKey);
    X = X(colRange(1):colRange(end));
    Z = squeeze(sliceDF(nexObj.DF_postOp.df, ptr, [rowKey, colKey], "range"));
    if ptr.(rowKey).dim > ptr.(colKey).dim
        Z = Z';
    end

    %% Update canvas
    canvas = nexObj.Figure.panel0.tiles.graphics.canvas;
    set(canvas, "XData", X, "YData", Y, "ZData", Z, "CData", Z);

    %% View / limits
    XLim = nexObj.DF_postOp.ax.(colKey);
    YLim = nexObj.DF_postOp.ax.(rowKey);
    ax = nexObj.Figure.panel0.tiles.ax;
    ax.ZLim = [zLim_low, zLim_high];
    ax.YLim = [YLim(rowRange(1)),YLim(rowRange(end))];
    ax.XLim = [XLim(colRange(1)),XLim(colRange(end))];
    clim(ax, [cLim_low, cLim_high]);

    %% Title
    axTitle = nexTract_axisTitle(nexObj, nexObj.DF_postOp);
    title(ax, axTitle, "Color", nexObj.nexon.settings.Colors.cyberGreen);

    drawnow limitrate;
end
