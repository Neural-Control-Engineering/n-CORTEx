function updateTimeCourse(shank, timeCourse)
    regMap = shank.regMap;
    dataFrame = timeCourse.dataFrame;
    ptr = timeCourse.UserData.tilePtr;
    % update tileset
    tileSetFields = fieldnames(timeCourse.tcFigure.panel1.tiles.Axes);    
    regMap.channel=arrayfun(@(x) x{1}, regMap.channel, "UniformOutput",true);
    for i = 1:length(tileSetFields)
        tileID = tileSetFields{i};
      
        ptrIdx = ceil(size(dataFrame,1)/(length(tileSetFields)))*ptr+i;
        traceColor = sprintf("#%s",regMap(regMap.channel==ptrIdx,:).color{1});        
        regName = regMap(regMap.channel==ptrIdx,:).region{1};
        updatePlotAx(timeCourse.tcFigure.panel1.tiles.Axes.(tileID), [], dataFrame(ptrIdx,:), traceColor);
        timeCourse.tcFigure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", regName);            
        colorAx_green(timeCourse.tcFigure.panel1.tiles.Axes.(tileID));
      
    end
    drawnow
end