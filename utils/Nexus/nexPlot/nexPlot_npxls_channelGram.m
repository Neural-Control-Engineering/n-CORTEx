function channelGram = nexPlot_npxls_channelGram(nexon, shank, channelGram)            
    %% DRAW PLOT
    channelGram.chgFigure.fh = uifigure("Position",[100,1260,600,500],"Color",[0,0,0]);   
    % plot panel
    channelGram.chgFigure.panel1.ph=uipanel(channelGram.chgFigure.fh,"Position",[5,5,490,470],"BackgroundColor",[0,0,0]);
    % opCfg entry bar
    channelGram.chgFigure.panel2.ph = uipanel(channelGram.chgFigure.fh,"Position",[500,5, 90, 470],"BackgroundColor",[0,0,0]);
    channelGram.chgFigure.panel2.entryPanel = breakoutEditFieldsV2(nexon, channelGram, channelGram.chgFigure.panel2.ph, channelGram.opCfg.entryParams);
    channelGram.chgFigure.panel1.tiles.t = tiledlayout(channelGram.chgFigure.panel1.ph,1,1);
    % User Input Buttons
    channelGram.chgFigure.playButton = uibutton(channelGram.chgFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)nexPlayPause(channelGram),"Position",[5,477,22,22]); % next            
    % channel gram
    channelGram.chgFigure.panel1.tiles.Axes.channelGram = nexttile(channelGram.chgFigure.panel1.tiles.t);           
    channelGram.chgFigure.panel1.tiles.Axes.channelGram= surf(channelGram.chgFigure.panel1.tiles.Axes.channelGram,"CData",[]);
        % view(channelGram.chgFigure.panel1.tiles.Axes.channelGram.Parent, [30 30]);  % Adjust the 3D view angle
    channelGram.chgFigure.panel1.tiles.Axes.channelGram.EdgeColor="none";              
    % grab and index first dataframe
    df_in = channelGram.dataFrame;
    frameNum = channelGram.frameNum;                                      
    df_in = df_in(:,frameNum:frameNum+channelGram.opCfg.entryParams.windowLen);            
    %% OPERATE
    % operate on dataframe with configured fcn
    opArgs = channelGram.opCfg.entryParams;            
    opFcn_out = channelGram.opCfg.opFcn(df_in, opArgs);   
    %% VISUALIZE
    % figure color mapping            
    load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(channelGram.chgFigure.fh,CT);
    % recover operation outputs
    df_out = opFcn_out.df;
    ax = opFcn_out.ax;
    visArgs = channelGram.visCfg.entryParams;
    visFcn_out = channelGram.visCfg.visFcn(nexon, shank, channelGram, df_out, ax, visArgs);
    channelGram.chgFigure = visFcn_out.fhObj;               
end