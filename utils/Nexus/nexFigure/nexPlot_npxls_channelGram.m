function nexObj = nexPlot_npxls_channelGram(nexObj)            
    nexon = nexObj.nexon;
    %% DRAW PLOT
    nexObj.Figure.fh = uifigure("Position",[100,1260,600,500],"Color",[0,0,0]);   
    % plot panel
    nexObj.Figure.panel1.ph=uipanel(nexObj.Figure.fh,"Position",[5,5,490,470],"BackgroundColor",[0,0,0]);
    % opCfg entry bar
    nexObj.Figure.panel2.ph = uipanel(nexObj.Figure.fh,"Position",[500,5, 90, 470],"BackgroundColor",[0,0,0]);
    nexObj.Figure.panel2.entryPanel = breakoutEditFieldsV2(nexon, nexObj, nexObj.Figure.panel2.ph, nexObj.opCfg.entryParams);
    nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,1,1);
    % User Input Buttons
    nexObj.Figure.playButton = uibutton(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)nexPlayPause(nexObj),"Position",[5,477,22,22]); % next            
    % channel gram
    nexObj.Figure.panel1.tiles.Axes.channelGram = nexttile(nexObj.Figure.panel1.tiles.t);           
    nexObj.Figure.panel1.tiles.Axes.channelGram= surf(nexObj.Figure.panel1.tiles.Axes.channelGram,"CData",[]);
        % view(channelGram.chgFigure.panel1.tiles.Axes.channelGram.Parent, [30 30]);  % Adjust the 3D view angle
    nexObj.Figure.panel1.tiles.Axes.channelGram.EdgeColor="none";              
    % grab and index first dataframe
    df_in = nexObj.dataFrame;
    frameNum = nexObj.frameNum;                                      
    df_in = df_in(:,frameNum:frameNum+nexObj.opCfg.entryParams.windowLen);            
    %% OPERATE
    % operate on dataframe with configured fcn
    opArgs = nexObj.opCfg.entryParams;            
    opFcn_out = nexObj.opCfg.opFcn(df_in, opArgs);   
    %% VISUALIZE
    % figure color mapping            
    load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);
    % recover operation outputs
    df_out = opFcn_out.df;
    ax = opFcn_out.ax;
    visArgs = nexObj.visCfg.entryParams;
    visFcn_out = nexObj.visCfg.visFcn(nexon, nexObj.Parent, nexObj, df_out, ax, visArgs);
    nexObj.Figure = visFcn_out.fhObj;               
end