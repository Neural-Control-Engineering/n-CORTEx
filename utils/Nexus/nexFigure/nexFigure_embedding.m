function nexFigure_embedding(nexObj)
    %% DRAW FIGURE
    nexObj.Figure.fh = uifigure("Position",[100, 500, 1020, 620], "Color",[0,0,0]);
    % plot panel
    nexObj.Figure.panel1.ph=uipanel(nexObj.Figure.fh,"Position",[5,5,600,580],"BackgroundColor",[0,0,0]);
    panel2.ph = uipanel(nexObj.Figure.fh,"Position",[610,295,200,290],"BackgroundColor",[0,0,0]); % opCfg
    panel3.ph = uipanel(nexObj.Figure.fh,"Position",[610,5,200,285],"BackgroundColor",[0,0,0],"Scrollable","on");
    panel4.ph = uipanel(nexObj.Figure.fh,"Position",[815,5,200,580],"BackgroundColor",[0,0,0],"Scrollable","on"); % visCfg
    % operation control panel
    opCfgEntryChangedFcn = str2func("opCfgEntryChanged");    
    opArgs = nexObj.opCfg.entryParams;
    nexObj.Figure.panel2 = nexObj_cfgPanel(nexObj.nexon, nexObj, panel2, opArgs, opCfgEntryChangedFcn,[]);
    nexObj.Figure.computeBtn = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",nexObj.nexon.settings.Colors.cyberGreen,"FontColor",[0,0,0],"Position",[10,10,180,50],"Text","","ButtonPushedFcn",@(~,~)nexCompute_embedding(nexObj, opArgs));
    % selection control panels    
    nexObj.Figure.panel3 = nexObj_listCfgPanel(nexObj.nexon, panel3, nexObj.visSelection, [3,1]);
    nexObj.Figure.panel4 = nexObj_listCfgPanel(nexObj.nexon, panel4, nexObj.labelSelection, []);
    % Peripheral edit fields
    updateDfIDFcn = str2func("nexUpdate_dfID");
    updateOpFcnFcn = str2func("nexUpdate_opFcn");
    nexObj.Figure.dfIDEditField = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexObj.nexon.settings.Colors.cyberGreen,"Position",[5,590,200,25],"Value",nexObj.dfID,"ValueChangedFcn",@(src,event)updateDfIDFcn(src,event,nexObj.nexon,nexObj));
    nexObj.Figure.opFcnEditField = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexObj.nexon.settings.Colors.cyberGreen,"Position",[610,590,200,25],"Value",func2str(nexObj.opCfg.opFcn),"ValueChangedFcn",@(src,event)updateOpFcnFcn(src, event, nexObj));    
    % draw plot (empty)
    nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,1,1);
    nexObj.Figure.panel1.tiles.Axes.embedding = nexttile(nexObj.Figure.panel1.tiles.t);
    nexObj.Figure.panel1.tiles.Axes.embedding = scatter3(nexObj.Figure.panel1.tiles.Axes.embedding, [], [], [], 50, 'b', 'filled',"ButtonDownFcn",@(src,event)nexTraceback_embedding(src, event, nexObj));
    colorAx_green(nexObj.Figure.panel1.tiles.Axes.embedding);
    % color mapping
    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);
    % add windowKeyListner
    nexObj.keyListener = nexObj_windowKeyListener(nexObj.Figure.fh);
    
end