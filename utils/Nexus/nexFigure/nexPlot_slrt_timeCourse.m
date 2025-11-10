function nexObj = nexPlot_slrt_timeCourse(nexon, nexObj)
    % router = nexon.console.BASE.router;
    params = nexon.console.BASE.params;
    Fs = nexObj.UserData.Fs;
    % preBuffer = 3.5;
    preBuffer = 1;
    % df = nexObj.dataFrame;
    DF = nexObj.DF;
    dfIDs = nexObj.dfIDs;
    nexObj.Figure.fh =uifigure("Position",[25,560,430,250],"Color",[0,0,0]);
    load(fullfile(params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,280,240],"BackgroundColor",[0,0,0],"Scrollable","on");  
    panel2.ph = uipanel(nexObj.Figure.fh,"Position",[285,5,140,240],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel2 = nexObj_listCfgPanel(nexObj.nexon, panel2, nexObj.eventAlignmentSelection, 1);
    % draw buttons
    % nexObj.Figure.nextButton = uibutton(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)tileShift(nexon, shank,  nexObj, 1),"Position",[965,1270,25,15]); % next
    % nexObj.Figure.prevButton = uibutton(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)tileShift(nexon, shank, nexObj, 0),"Position",[935,1270,25,15]); % prev
    % draw subplots
    % nexObj.Figure.panel1.tiles.s = tiledlayout(nexObj.Figure.panel1.ph,numTiles,1,"TileSpacing","tight"); 
    numTiles = size(dfIDs,1);    
    nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,"flow","TileSpacing","tight"); 
    nexObj.Figure.panel1.tiles.graphics=struct;
    dfFields = fieldnames(DF.df);
    for i = 1:numTiles
        % dfID = dfIDs(i);
        % df_i = df{i}; % cell array
        dfField = dfFields{i};
        df_i = DF.df.(dfField);
        % t_df = [1:size(df_i,2)] ./ Fs - preBuffer; % associated time vector
        % t_df = DF.ax.t.(sprintf("%s_time",dfField));
        t_df = DF.ax.t.(dfField);
        % dfID_i = dfID(i); % string array
        tileID = sprintf("tile_%s",dfField);
        ax_canvas = nexttile(nexObj.Figure.panel1.tiles.t);        
        nexObj.Figure.panel1.tiles.Axes.(tileID) = ax_canvas;                
        axID = sprintf("xMarkers_%s",dfIDs(i));        
        % traceColor = sprintf("#%s",regMap(regMap.channel==i,:).color{1});
        traceColor = [1,1,1]; % temporary default
        % regName = regMap(regMap.channel==i,:).region{1};
        canvas_l = plot(nexObj.Figure.panel1.tiles.Axes.(tileID),t_df,df_i,"Color",traceColor);
        nexObj.Figure.panel1.tiles.graphics.(tileID) = canvas_l;    
        hold(ax_canvas,"on");
        % nexObj.Figure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", dfID_i);                       
        nexObj.Figure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", dfField);                       
        colorAx_green(nexObj.Figure.panel1.tiles.Axes.(tileID));        
        graphics = nex_generateEventMarkers(nexObj,ax_canvas);
        nexObj.Figure.panel1.tiles.graphics.(axID) = graphics;
        hold(ax_canvas,"off");
        %% Markers
        % t Marker
        tIdx = nexObj.nexon.console.BASE.controlPanel.clock;
        graphic = xline(ax_canvas,tIdx,"Color",nexObj.nexon.settings.Colors.cyberGreen);
        nexObj.Figure.panel1.tiles.graphics.(("tMarker")) = nexObj_tMarker(nexObj, graphic, nexObj.nexon.console.BASE.controlPanel, 0);
    end

end