function channelGram = nexPlot_channelGram(nexon, shank, channelGram)            
    %% DRAW PLOT
    channelGram.chgFigure.fh = uifigure("Position",[100,1260,650,800],"Color",[0,0,0]);   
    % plot panel
    channelGram.chgFigure.panel1.ph=uipanel(channelGram.chgFigure.fh,"Position",[5,5,490,760],"BackgroundColor",[0,0,0]);
    % opCfg entry bar
    panel2.ph = uipanel(channelGram.chgFigure.fh,"Position",[500, 5, 145, 200],"BackgroundColor",[0,0,0]);
    panel3.ph = uipanel(channelGram.chgFigure.fh,"Position",[500, 210, 145, 300], "BackgroundColor",[0,0,0]);
    panel4.ph = uipanel(channelGram.chgFigure.fh,"Position",[500, 515, 145,250],"BackgroundColor",[0,0,0]);
    % channelGram.chgFigure.panel2.entryPanel = breakoutCfgFields(nexon, channelGram, channelGram.chgFigure.panel2.ph, channelGram.opCfg.entryParams);
    opCfgEntryChangedFcn = str2func("opCfgEntryChanged");
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged");
    cfgEntryChangedFcn = str2func("cfgEntryChanged");
    opArgs = channelGram.opCfg.entryParams;    
    visArgs = channelGram.visCfg.entryParams;
    aniArgs = channelGram.aniCfg.entryParams;
    channelGram.chgFigure.panel2 = nexObj_cfgPanel(nexon, channelGram, panel2, opArgs, opCfgEntryChangedFcn, []);    
    channelGram.chgFigure.panel3 = nexObj_cfgPanel(nexon, channelGram, panel3, visArgs, visCfgEntryChangedFcn, []);        
    aniChangedFcnArgs.cfgFieldName = "aniCfg";
    channelGram.chgFigure.panel4 = nexObj_cfgPanel(nexon, channelGram, panel4, aniArgs, cfgEntryChangedFcn, aniChangedFcnArgs);        
    % begin plot layout
    channelGram.chgFigure.panel1.tiles.t = tiledlayout(channelGram.chgFigure.panel1.ph,1,1);
    % User Input Buttons/Fields
    channelGram.chgFigure.playButton = uibutton(channelGram.chgFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)nexPlayPause(channelGram),"Position",[5,770,25,25]); % next            
    updateDfIDFcn = str2func("nexUpdate_dfID");
    updateOpFcnFcn = str2func("nexUpdate_opFcn");
    channelGram.chgFigure.dfIDEditField = uieditfield(channelGram.chgFigure.fh,"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"Position",[500, 770, 145, 25], "Value",channelGram.dfID,"ValueChangedFcn",@(src,event)updateDfIDFcn(src,event,nexon,channelGram));
    channelGram.chgFigure.opFcnEditField = uieditfield(channelGram.chgFigure.fh,"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"Position",[35,770,200,25],"Value",func2str(channelGram.opCfg.opFcn),"ValueChangedFcn",@(src,event)updateOpFcnFcn(src, event, channelGram));
    % channel gram
    channelGram.chgFigure.panel1.tiles.Axes.channelGram = nexttile(channelGram.chgFigure.panel1.tiles.t);           
    channelGram.chgFigure.panel1.tiles.Axes.channelGram= surf(channelGram.chgFigure.panel1.tiles.Axes.channelGram,"CData",[]);
        % view(channelGram.chgFigure.panel1.tiles.Axes.channelGram.Parent, [30 30]);  % Adjust the 3D view angle
    channelGram.chgFigure.panel1.tiles.Axes.channelGram.EdgeColor="none";              
    % grab and index first dataframe
    df_in = channelGram.dataFrame;
    frameNum = channelGram.frameNum;                                      
    df_in = df_in(:,frameNum:frameNum+channelGram.aniCfg.entryParams.windowLen);            
    %% OPERATE
    % operate on dataframe with configured fcn    
    opArgs.frameNum = channelGram.frameNum;
    opFcn_out = channelGram.opCfg.opFcn(df_in, opArgs);   
    %% VISUALIZE
    % figure color mapping            
    load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(channelGram.chgFigure.fh,CT);
    % recover operation outputs
    df_out = opFcn_out.df;
    ax = opFcn_out.ax;    
    try
        channelGram.visCfg.visFcn(nexon, channelGram, visArgs);
    catch e
        disp(getReport(e))
    end
    % channelGram.chgFigure = visFcn_out.fhObj;               
end