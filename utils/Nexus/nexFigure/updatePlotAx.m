function updatePlotAx(tAx, x, y, C)
    plts = get(tAx,"Children");
    if isempty(x)
        x = [1:size(y,2)];
    end
    if isempty(plts)
        plot(tAx,x,y);        
    else
        for i = 1:size(plts,1)
            delete(plts(1));
            plts = get(tAx,"Children");
        end
        % add sig to plot        
        line(x,y,"Parent",tAx,"Color",C);
        % line(x,y,"Parent",tAx,"Color",[1,1,1]);
    end
    % colorAx_green(dash.panel1.pltAx);
    % drawnow
end