function tileShift(nexon, shank, npxlsTimeCourse, direction)
    % lfp = nexon.console.npxlsLFP.UserData.lfp;
    % dataFrame = npxlsTimeCourse.dataFrame;
    dataFrame = npxlsTimeCourse.DF.df;
    ptr = npxlsTimeCourse.UserData.tilePtr;
    % Region Mapping (npxls only)
    regMap = shank.regMap;
    regMap.channel=arrayfun(@(x) x{1}, regMap.channel, "UniformOutput",true);
    Fs = npxlsTimeCourse.UserData.Fs;
    t_df = [1:size(dataFrame,2)] ./ Fs - 3.5;
    ptr_prior = ptr;
    switch direction
        case 1 % up
            npxlsTimeCourse.UserData.tilePtr = ptr+1;
            ptr = ptr+1;
            % C = [0.24,0.94,0.46];
        case 0 % down
            npxlsTimeCourse.UserData.tilePtr = ptr - 1;
            ptr = ptr-1;
            % C = [1,1,1];
    end
    % update tileset
    tileSetFields = fieldnames(npxlsTimeCourse.tcFigure.panel1.tiles.Axes);    
    for i = 1:length(tileSetFields)
        tileID = tileSetFields{i};
        try
            ptrIdx = ceil(size(dataFrame,1)/(length(tileSetFields)))*ptr+i;
            traceColor = sprintf("#%s",regMap(regMap.channel==ptrIdx,:).color{1});        
            regName = regMap(regMap.channel==ptrIdx,:).region{1};
            updatePlotAx(npxlsTimeCourse.tcFigure.panel1.tiles.Axes.(tileID), t_df, dataFrame(ptrIdx,:), traceColor);
            npxlsTimeCourse.tcFigure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", regName);            
            colorAx_green(npxlsTimeCourse.tcFigure.panel1.tiles.Axes.(tileID));
        catch e
            disp(e);
            npxlsTimeCourse.UserData.tilePtr = ptr_prior;
        end
    end
    drawnow
end