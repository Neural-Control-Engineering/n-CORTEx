function nexFigure_pixelGram(nexObj)
    nexObj.Figure.fh = uifigure("Position",[100,1060,450,830],"Color",[0,0,0]);
    % neuropixels plot panel
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,300,790],"BackgroundColor",[0,0,0]);
    % config panels
    %% Pooling control
    panel1.ph = uipanel(nexObj.Figure.fh,"Position",[310,645,135,150],"BackgroundColor",[0,0,0],"Scrollable","on");
    poolCfgChangedFcn = str2func("poolCfgEntryChanged");
    nexObj.Figure.panel1 = nexObj_poolCfgPanel_v2(nexObj, panel1, poolCfgChangedFcn);
    %% Operation control
    panel2.ph = uipanel(nexObj.Figure.fh,"Position",[310,440,135,200],"BackgroundColor",[0,0,0],"Scrollable","on");
    opCfgEntryChangedFcn = str2func("opCfgEntryChanged_v2");    
    if ~isempty(nexObj.cfg.opCfg)
        opArgs = nexObj.cfg.opCfg.entryParams;
        nexObj.Figure.panel2 = nexObj_cfgPanel_spinner(nexObj.nexon, nexObj, panel2, opArgs, opCfgEntryChangedFcn, []);
    else
        nexObj.Figure.panel2 = panel2;
    end
    %% Visualization control
    panel3.ph = uipanel(nexObj.Figure.fh,"Position",[310,235,135,200],"BackgroundColor",[0,0,0],"Scrollable","on");
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged_v2");
    visArgs = nexObj.cfg.visCfg.entryParams;
    nexObj.Figure.panel3 = nexObj_cfgPanel_v2(nexObj, nexObj.cfg.visCfg, panel3, visArgs, visCfgEntryChangedFcn, []);
    %% Animation control
    panel4.ph = uipanel(nexObj.Figure.fh,"Position",[310,130,135,100],"BackgroundColor",[0,0,0],"Scrollable","on");        
    cfgEntryChangedFcn = str2func("cfgEntryChanged_v2");
    aniArgs = nexObj.cfg.aniCfg.entryParams;    
    uiFieldArgs.entryHeightScaler=5;
    nexObj.Figure.panel4 = nexObj_cfgPanel_v2(nexObj, nexObj.cfg.aniCfg, panel4, aniArgs, cfgEntryChangedFcn, uiFieldArgs);
    %% Axis control
    panel5.ph = uipanel(nexObj.Figure.fh,"Position",[310,5,135,120],"BackgroundColor",[0,0,0],"Scrollable","on");
    % axisPtrChangedFcn = str2func("axisPtrChanged");
    nexObj.Figure.panel5 = nexObj_axisPanel(nexObj, nexObj.DF_postOp.ptr, panel5);
    %% UI Control
    nexObj.Figure.playButton = uibutton("state","Parent",nexObj.Figure.fh,"Position",[5,800,25,25],"BackgroundColor",[0,0,0],"ValueChangedFcn",@(~,~) nexObj.startPlayer());
    nexObj.Figure.axSelDropDown = uidropdown(nexObj.Figure.fh,"Position",[35, 800, 80, 25], "BackgroundColor",nexObj.nexon.settings.Colors.cyberGreen,"Items",fieldnames(nexObj.DF_postOp.ptr));
    % nexObj.Figure.dfIDEditField_source = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexObj.nexon.settings.Colors.cyberGreen,"Position",[500, 770, 145, 25], "Value",nexObj.dfID_source,"ValueChangedFcn",@(src,event)updateDfIDFcn(src,event,nexObj.nexon,nexObj));
    % nexObj.Figure.opFcnEditField = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"Position",[35,770,200,25],"Value",func2str(nexObj.cfg.opCfg.opFcn),"ValueChangedFcn",@(src,event)updateOpFcnFcn(src, event, nexObj));    
    % nexObj.Figure.operateButton = uibutton(nexObj.Figure.fh,"ButtonPushedFcn",@(~,~) nexObj.operate());
    
    
    % Build graphics
    df = nexObj.DF_postOp.df(:,:);
    axPtr = nexObj.DF_postOp.ptr;
    axSel = string(nexObj.Figure.axSelDropDown.Value);
    df_slice = 20*log10(abs(sliceDF(df, axPtr, axSel)));
    try
        df_NT = mat2NT(df_slice);
    catch e
        disp("NT Mapping unsuccessful")
        disp(getReport(e));
        df_NT = [];
    end

    % color mapping
    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);

    nexObj.Figure.panel0.tiles.t = tiledlayout(nexObj.Figure.panel0.ph,1,1);
    nexObj.Figure.panel0.tiles.ax = nexttile(nexObj.Figure.panel0.tiles.t);
    nexObj.Figure.panel0.tiles.graphics.canvas = imagesc(nexObj.Figure.panel0.tiles.ax, df_NT);    
    
    % colormap(nexObj.Figure.panel0.tiles.ax,CT);
    % colorbar(nexObj.Figure.panel0.tiles.ax,"Color",nexObj.nexon.settings.Colors.cyberGreen);
    colorAx_green(nexObj.Figure.panel0.tiles.ax);



end