function nexObj = nexFigure_channelGram(nexObj)            
    nexon = nexObj.nexon;
    shank = nexObj.Parent;
    %% DRAW PLOT
    nexObj.Figure.fh = uifigure("Position",[100,1260,650,800],"Color",[0,0,0]);   
    % plot panel
    nexObj.Figure.panel1.ph=uipanel(nexObj.Figure.fh,"Position",[5,5,490,760],"BackgroundColor",[0,0,0]);
    nexObj.Figure.panel0.ph=uipanel(nexObj.Figure.fh,"Position",[500,5,145,760],"BackgroundColor",[0,0,0],"scrollable","on");
    % opCfg entry bar
    % panel2.ph = uipanel(nexObj.Figure.fh,"Position",[500, 5, 145, 200],"BackgroundColor",[0,0,0]);
    % panel3.ph = uipanel(nexObj.Figure.fh,"Position",[500, 210, 145, 300], "BackgroundColor",[0,0,0]);
    % panel4.ph = uipanel(nexObj.Figure.fh,"Position",[500, 515, 145,250],"BackgroundColor",[0,0,0]);
    panel2.ph = uipanel(nexObj.Figure.panel0.ph,"Position",[1, 1, 125, 200],"BackgroundColor",[0,0,0]);
    panel3.ph = uipanel(nexObj.Figure.panel0.ph,"Position",[1, 206, 125, 300], "BackgroundColor",[0,0,0]);
    panel4.ph = uipanel(nexObj.Figure.panel0.ph,"Position",[1, 511, 125,250],"BackgroundColor",[0,0,0]);
    panel5.ph = uipanel(nexObj.Figure.panel0.ph,"Position",[1,766,125,150],"BackgroundColor",[0,0,0],"Scrollable","off");
    % channelGram.chgFigure.panel2.entryPanel = breakoutCfgFields(nexon, channelGram, channelGram.chgFigure.panel2.ph, channelGram.opCfg.entryParams);
    %% CFG ENTRIES
    opCfgEntryChangedFcn = str2func("opCfgEntryChanged");
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged");
    cfgEntryChangedFcn = str2func("cfgEntryChanged");
    opArgs = nexObj.opCfg.entryParams;    
    visArgs = nexObj.visCfg.entryParams;
    aniArgs = nexObj.aniCfg.entryParams;
    nexObj.Figure.panel2 = nexObj_cfgPanel(nexon, nexObj, panel2, opArgs, opCfgEntryChangedFcn, []);    
    nexObj.Figure.panel3 = nexObj_cfgPanel(nexon, nexObj, panel3, visArgs, visCfgEntryChangedFcn, []);        
    aniChangedFcnArgs.cfgFieldName = "aniCfg";
    nexObj.Figure.panel4 = nexObj_cfgPanel(nexon, nexObj, panel4, aniArgs, cfgEntryChangedFcn, aniChangedFcnArgs);        
    %% BINNING CFG
    binCfgChangedFcn = str2func("binCfgEntryChanged");
    nexObj.Figure.poolCfgPanel = nexObj_poolCfgPanel(nexObj, panel5, nexObj.poolCfg, binCfgChangedFcn);
    % begin plot layout
    nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,1,1);
    % User Input Buttons/Fields
    nexObj.Figure.playButton = uibutton(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)nexPlayPause(nexObj),"Position",[5,770,25,25]); % next            
    nexObj.Figure.scaleAnalysisButton = uibutton(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)nexObj.scaleAnalysis(),"Position",[240,770,25,25]);
    updateDfIDFcn = str2func("nexUpdate_dfID");
    updateOpFcnFcn = str2func("nexUpdate_opFcn");
    nexObj.Figure.dfIDEditField = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"Position",[500, 770, 145, 25], "Value",nexObj.dfID,"ValueChangedFcn",@(src,event)updateDfIDFcn(src,event,nexon,nexObj));
    nexObj.Figure.opFcnEditField = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"Position",[35,770,200,25],"Value",func2str(nexObj.opCfg.opFcn),"ValueChangedFcn",@(src,event)updateOpFcnFcn(src, event, nexObj));    
    % channel gram
    nexObj.Figure.panel1.tiles.Axes.channelGram = nexttile(nexObj.Figure.panel1.tiles.t);           
    nexObj.Figure.panel1.tiles.Axes.channelGram= surf(nexObj.Figure.panel1.tiles.Axes.channelGram,"CData",[]);
    % view(channelGram.chgFigure.panel1.tiles.Axes.channelGram.Parent, [30 30]);  % Adjust the 3D view angle
    nexObj.Figure.panel1.tiles.Axes.channelGram.EdgeColor="none";              
    % grab and index first dataframe
    df_in = nexObj.dataFrame;
    frameNum = nexObj.frameNum;                                      
    df_in = df_in(:,frameNum:frameNum+nexObj.aniCfg.entryParams.windowLen);            
    %% OPERATE
    % operate on dataframe with configured fcn    
    opArgs.frameNum = nexObj.frameNum;
    opFcn_out = nexObj.opCfg.opFcn(df_in, opArgs);   
    %% VISUALIZE
    % figure color mapping            
    load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);
    % recover operation outputs
    df_out = opFcn_out.df;
    ax = opFcn_out.ax;    
    try
        nexObj.visCfg.visFcn(nexon, nexObj, visArgs);
    catch e
        disp(getReport(e))
    end
    % channelGram.chgFigure = visFcn_out.fhObj;               
end