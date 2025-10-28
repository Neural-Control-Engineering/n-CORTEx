function nexFigure_embedding_single(nexObj)
    nexObj.Figure.fh = uifigure("Position",[100,500,1020,620],"Color",[0,0,0]);
    %% plot panel
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,600,580],"BackgroundColor",[0,0,0]);    
    %% Selection control (labeling)
    panel2.ph = uipanel(nexObj.Figure.fh,"Position",[610,5,200,440],"BackgroundColor",[0,0,0],"Scrollable","on");
    panel3.ph = uipanel(nexObj.Figure.fh,"Position",[815,5,200,440],"BackgroundColor",[0,0,0],"Scrollable","on");
    % nexObj.Figure.panel2 = nexObj_listCfgPanel(nexObj.nexon, panel2, labelSelection,[]); % select one label (color bar = behavior, time, etc.)
    % nexObj.Figure.panel3 = nexObj_listCfgPanel(nexObj.nexon, panel3, dimSelection, []); % select three dimensions
    %% Animation control
    panel1.ph = uipanel(nexObj.Figure.fh,"Position",[610,450,405,135],"BackgroundColor",[0,0,0],"Scrollable","on");
    cfgEntryChangedFcn = str2func("cfgEntryChanged_v2");
    uiFieldArgs.entryHeightScaler=5;
    aniArgs = nexObj.cfg.aniCfg.entryParams;
    nexObj.Figure.panel1 = nexObj_cfgPanel_v2(nexObj, nexObj.cfg.aniCfg, panel1, aniArgs, cfgEntryChangedFcn, uiFieldArgs);
    %% UI Control
    nexObj.Figure.playButton = uibutton("state","Parent",nexObj.Figure.fh,"Position",[5,590,25,25],"BackgroundColor",[0,0,0],"ValueChangedFcn",@(~,~)nexObj.startPlayer());    
    % Build graphics
    nexObj.Figure.panel0.tiles.t = tiledlayout(nexObj.Figure.panel0.ph,1,1);
    nexObj.Figure.panel0.tiles.ax = nexttile(nexObj.Figure.panel0.tiles.t);
    Z = nexObj.DF_postOp.df;
    Y = nexObj.DF_postOp.ax.t;
    dim1=1;dim2=2;dim3=3;
    nexObj.Figure.panel0.tiles.graphics.canvas = scatter3(nexObj.Figure.panel0.tiles.ax,Z(:,dim1),Z(:,dim2),Z(:,dim3),50,Y','filled');    
    % Color mapping
    colorAx_green(nexObj.Figure.panel0.tiles.ax);
    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);    
end