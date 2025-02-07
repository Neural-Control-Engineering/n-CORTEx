function timeCourse = nexPlot_slrt_timeCourse(nexon, timeCourse)
    % router = nexon.console.BASE.router;
    params = nexon.console.BASE.params;
    Fs = timeCourse.UserData.Fs;
    % preBuffer = 3.5;
    preBuffer = 1;
    df = timeCourse.dataFrame;
    dfID = timeCourse.dfID;
    timeCourse.tcFigure.fh =uifigure("Position",[25,560,1000,1300],"Color",[0,0,0]);
    load(fullfile(params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    timeCourse.tcFigure.panel1.ph1 = uipanel(timeCourse.tcFigure.fh,"Position",[5,5,990,1260],"BackgroundColor",[0,0,0]);  
    % draw buttons
    % timeCourse.tcFigure.nextButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)tileShift(nexon, shank,  timeCourse, 1),"Position",[965,1270,25,15]); % next
    % timeCourse.tcFigure.prevButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)tileShift(nexon, shank, timeCourse, 0),"Position",[935,1270,25,15]); % prev
    % draw subplots
    % timeCourse.tcFigure.panel1.tiles.s = tiledlayout(timeCourse.tcFigure.panel1.ph1,numTiles,1,"TileSpacing","tight"); 
    numTiles = size(df,1);
    
    timeCourse.tcFigure.panel1.tiles.t = tiledlayout(timeCourse.tcFigure.panel1.ph1,"flow","TileSpacing","tight"); 
    for i = 1:numTiles
        df_i = df{i}; % cell array
        t_df = [1:size(df_i,2)] ./ Fs - preBuffer; % associated time vector
        dfID_i = dfID(i); % string array
        tileID = sprintf("tile%s",dfID_i);
        timeCourse.tcFigure.panel1.tiles.Axes.(tileID) = nexttile(timeCourse.tcFigure.panel1.tiles.t);        
        % traceColor = sprintf("#%s",regMap(regMap.channel==i,:).color{1});
        traceColor = [1,1,1]; % temporary default
        % regName = regMap(regMap.channel==i,:).region{1};
        plot(timeCourse.tcFigure.panel1.tiles.Axes.(tileID),t_df,df_i,"Color",traceColor);
        timeCourse.tcFigure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", dfID_i);                       
        colorAx_green(timeCourse.tcFigure.panel1.tiles.Axes.(tileID));        
    end
end