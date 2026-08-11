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
        % Guard: this trial may lack a signal the figure has a tile for — e.g. a
        % neural-only capture trial has no SLRT signals (nexSLRT_compileDataFrames
        % skips them), so DF.df has no such field. Blank the tile instead of
        % erroring during the post-capture auto-route (nex_routeToTrial).
        hasSig = false;
        try
            hasSig = isstruct(timeCourse.DF.df) && isfield(timeCourse.DF.df, signalID);
        catch
        end
        if ~hasSig
            try
                timeCourse.Figure.panel1.tiles.graphics.(tileID).YData = [];
                timeCourse.Figure.panel1.tiles.graphics.(tileID).XData = [];
            catch
            end
            continue
        end
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