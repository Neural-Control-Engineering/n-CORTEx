function updateLinePlot(pltAx, x, y, xLines)
    % plts = get(pltAx,"Children");
    plts = findall(pltAx,'Type','Line');
    if isempty(plts)
        plot(pltAx, x, y,"Color",[0.24,0.94,0.46]);
        if ~isempty(xLines)
            % ADD NEW XLINES
            for i = 1:length(xLines)
                xLineCoord = xLines(i);
                xline(pltAx, xLineCoord,"Color",[1,1,1]);
            end
        end
    else
        for i = 1:size(plts,1)
            delete(plts(1));
            plts = get(pltAx,"Children");             
        end
        % Find all xline objects (if Any)
        xlines = findall(pltAx, 'Type', 'ConstantLine');
        % Delete all xlines
        delete(xlines);
        if ~isempty(xLines)
            % ADD NEW XLINES
            for i = 1:length(xLines)
                xLineCoord = xLines(i);
                xline(pltAx, xLineCoord,"Color",[1,1,1]);
            end
        end
        % add sig to plot
        line(x,y,"Parent",pltAx,"Color",[0.24,0.94,0.46]);        
    end
    colorAx_green(pltAx);
    drawnow
end