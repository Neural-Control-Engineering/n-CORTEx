function updateSlrtTimeCourse(timeCourse, colorMap)
    % preBuffer = timeCourse.UserData.preBufferLen; % event prior duration/delay count
    preBuffer = 3.5;
    Fs = timeCourse.UserData.Fs;
    dataFrame = timeCourse.dataFrame;
    
    dfIDs = timeCourse.dfIDs;
    tileSetFields = fieldnames(timeCourse.Figure.panel1.tiles.Axes);   
    for i = 1:length(tileSetFields)
        tileID = tileSetFields{i};     
        signalID = strrep(tileID,"tile_","");
        signalID_hyph = strrep(signalID,"_","-");
        % retrieve corresponding df
        dfID_tileID = split(tileID,"_"); dfID = convertCharsToStrings(dfID_tileID(end));
        % df_idx = find(dfID==signalID);       
        % df_i = dataFrame{df_idx};
        df_i = timeCourse.DF.df.(signalID)';
        t_df = [1:size(df_i,2)] ./ Fs - preBuffer;    
        traceColor = [1,1,1];
        canvas_l = timeCourse.Figure.panel1.tiles.graphics.(tileID);
        canvas_l.YData = df_i;
        canvas_l.XData = t_df;
        % updatePlotAx(timeCourse.Figure.panel1.tiles.Axes.(tileID), t_df, df_i,traceColor);
        timeCourse.Figure.panel1.tiles.Axes.(tileID).YLabel.String = signalID_hyph;                  
        colorAx_green(timeCourse.Figure.panel1.tiles.Axes.(tileID));      
    end
    % drawnow
    
end