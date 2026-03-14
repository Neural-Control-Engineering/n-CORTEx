function nexVisualization_monoGram(nexObj, args)

    % CFG HEADER    
    zLim_low  = args.zLim_low;  % default = -1
    zLim_high = args.zLim_high; % default = 1
    cLim_low = args.cLim_low; % default = -11.5
    cLim_high = args.cLim_high; % default = -9.5

    %% Slice DF using ptr + domain display axes
    rowKey = nexObj.domain.display.rows;
    colKey = nexObj.domain.display.cols;
    ptr    = nexObj.DF_postOp.ptr;
    Y = nexObj.DF_postOp.ax.(rowKey);
    X = nexObj.DF_postOp.ax.(colKey);
    Z = squeeze(sliceDF(nexObj.DF_postOp.df, ptr, [rowKey, colKey], "range"));
    if ptr.(rowKey).dim > ptr.(colKey).dim
        Z = Z';
    end

    %% Update canvas
    canvas = nexObj.Figure.panel0.tiles.graphics.canvas;
    set(canvas, "XData", X, "YData", Y, "ZData", Z, "CData", Z);

    %% View / limits
    ax = nexObj.Figure.panel0.tiles.ax;
    ax.ZLim = [zLim_low, zLim_high];
    clim(ax, [cLim_low, cLim_high]);

    %% Title
    axTitle = nexTract_axisTitle(nexObj, nexObj.DF_postOp);
    title(ax, axTitle, "Color", nexObj.nexon.settings.Colors.cyberGreen);

    drawnow limitrate;
end
