function updateSlrtTimeCourse(timeCourse, colorMap)
    % preBuffer = timeCourse.UserData.preBufferLen; % event prior duration/delay count
    preBuffer = 1;
    Fs = timeCourse.UserData.Fs;
    dataFrame = timeCourse.dataFrame;
    
    dfID = timeCourse.dfID;
    tileSetFields = fieldnames(timeCourse.tcFigure.panel1.tiles.Axes);   
    for i = 1:length(tileSetFields)
        tileID = tileSetFields{i};     
        signalID = strrep(tileID,"tile","");
        signalID_hyph = strrep(signalID,"_","-");
        % retrieve corresponding df
        df_idx = find(dfID==signalID);       
        df_i = dataFrame{df_idx};
        t_df = [1:size(df_i,2)] ./ Fs - preBuffer;    
        traceColor = [1,1,1];
        updatePlotAx(timeCourse.tcFigure.panel1.tiles.Axes.(tileID), t_df, df_i,traceColor);
        timeCourse.tcFigure.panel1.tiles.Axes.(tileID).YLabel.String = signalID_hyph;                  
        colorAx_green(timeCourse.tcFigure.panel1.tiles.Axes.(tileID));      
    end
    drawnow
    
end