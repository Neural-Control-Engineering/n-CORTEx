function updateTimeCourse(shank, timeCourse, altRegMap)
    preBuffer = 3.5; % sglx 3.5 seconds prebuffered
    Fs = timeCourse.UserData.Fs;
     if ~isempty(altRegMap) 
        regMap = altRegMap;
    else 
        regMap = shank.regMap;
    end
    dataFrame = timeCourse.dataFrame;
    t_df = [1:size(dataFrame,2)] ./ Fs - preBuffer;
    ptr = timeCourse.UserData.tilePtr;
    % update tileset
    tileSetFields = fieldnames(timeCourse.tcFigure.panel1.tiles.Axes);   
    try
        regMap.channel=arrayfun(@(x) x{1}, regMap.channel, "UniformOutput",true);
    catch e
        disp(e);
    end
    for i = 1:length(tileSetFields)
        tileID = tileSetFields{i};      
        ptrIdx = ceil(size(dataFrame,1)/(length(tileSetFields)))*ptr+i;
        try
            traceColor = sprintf("#%s",regMap(regMap.channel==ptrIdx,:).color{1});        
            regName = regMap(regMap.channel==ptrIdx,:).region{1};
            updatePlotAx(timeCourse.tcFigure.panel1.tiles.Axes.(tileID), t_df, dataFrame(ptrIdx,:), traceColor);
            timeCourse.tcFigure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", regName);            
        catch
            updatePlotAx(timeCourse.tcFigure.panel1.tiles.Axes.(tileID), [], zeros(size(dataFrame(1,:))), traceColor);
            timeCourse.tcFigure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("--");            
        end
        
        colorAx_green(timeCourse.tcFigure.panel1.tiles.Axes.(tileID));      
    end
    drawnow
end