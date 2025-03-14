function nexFigure_embedding(nexObj)
    %% DRAW FIGURE
    nexObj.Figure.fh = uifigure("Position",[100, 500, 1020, 620], "Color",[0,0,0]);
    % plot panel
    nexObj.Figure.panel1.ph=uipanel(nexObj.Figure.fh,"Position",[5,5,600,580],"BackgroundColor",[0,0,0]);
    panel2.ph = uipanel(nexObj.Figure.fh,"Position",[610,295,200,290],"BackgroundColor",[0,0,0]); % opCfg
    panel3.ph = uipanel(nexObj.Figure.fh,"Position",[610,5,200,285],"BackgroundColor",[0,0,0]);
    panel4.ph = uipanel(nexObj.Figure.fh,"Position",[815,5,200,580],"BackgroundColor",[0,0,0]); % visCfg
    % 
    opCfgEntryChangedFcn = str2func("opCfgEntryChanged");
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged");
    opArgs = nexObj.opCfg.entryParams;
    visArgs = nexObj.visCfg.entryParams;
    nexObj.Figure.panel2 = nexObj_cfgPanel(nexObj.nexon, nexObj, panel2, opArgs, opCfgEntryChangedFcn,[]);
    nexObj.Figure.panel3 = nexObj_listCfgPanel(nexObj.nexon, nexObj, panel3, visArgs, visCfgEntryChangedFcn,[]);
    nexObj.Figure.panel4 = nexObj_listCfgPanel(nexObj.nexon, nexObj, panel4, [], visCfgEntryChangedFcn,[]);
    % Peripheral edit fields
    updateDfIDFcn = str2func("nexUpdate_dfID");
    updateOpFcnFcn = str2func("nexUpdate_opFcn");
    nexObj.Figure.dfIDEditField = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"Position",[5,585,200,25],"Value",nexObj.dfID,"ValueChangedFcn",@(src,event)updateDfIDFcn(src,event,nexObj.nexon,nexObj));
    nexObj.Figure.opFcnEditField = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"Position",[610,585,200,25],"Value",func2str(nexObj.opCfg.opFcn),"ValueChangedFcn",@(src,event)updateOpFcnFcn(src, event, nexObj));    
    % draw plot (empty)
    nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,1,1);
    nexObj.Figure.panel1.tiles.Axes.embedding = nexttile(nexObj.Figure.panel1.tiles.t);
    nexObj.Figure.panel1.tiles.Axes.embedding = scatter3(nexObj.Figure.panel1.tiles.Axes.embedding, [], [], [], 50, 'b', 'filled');
    colorAx_green(nexObj.Figure.panel1.tiles.Axes.embedding);
    % color mapping
    load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);
    
end