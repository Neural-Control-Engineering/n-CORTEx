function nexFigure_monoGraph(nexObj)
    nexObj.Figure.fh = uifigure("Position",[100, 1060, 1000, 400],"Color",[0,0,0]);
    %% Plot panel
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,800,360],"BackgroundColor",[0,0,0]);
    %% Cfg Panel
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[805,5,190,360],"BackgroundColor",[0,0,0],"Scrollable","on");
    %% Axis Control
    panel2.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[5,180,180,175],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel2 = nexObj_axisPanel(nexObj, nexObj.DF_postOp.ptr, panel2);
    %% Visualization Control
    panel3.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[5,5,180,180],"BackgroundColor",[0,0,0],"Scrollable",true);
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged_v2");
    nexObj.Figure.panel3 = nexObj_cfgPanel_v2(nexObj, nexObj.cfg.visCfg, panel3, nexObj.cfg.visCfg.entryParams, visCfgEntryChangedFcn, []);    
    %% Operation Control (try scaling fcns, etc.)
    if ~isempty(nexObj.cfg.opCfg)
        panel4.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[310,490,135,200],"BackgroundColor",[0,0,0],"Scrollable",true);
        opCfgEntryChangedFcn = str2func("opCfgEntryChanged_v2");    
        nexObj.Figure.panel4 = nexObj_cfgPanel_v2(nexObj.nexon, nexObj, panel4, opArgs, opCfgEntryChangedFcn, []);
    end
    %% UI CONTROL
    nexObj.Figure.axSelDropDown = uidropdown(nexObj.Figure.fh,"Position",[35, 370, 80, 25], "BackgroundColor",nexObj.nexon.settings.Colors.cyberGreen,"Items",fieldnames(nexObj.DF_postOp.ptr));
    updateDfIDFcn = str2func("nexUpdate_dfID");
    nexObj.Figure.dfIDEditField = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexObj.nexon.settings.Colors.cyberGreen,"Position",[850, 370, 150, 25],"Value",nexObj.dfID_source,"ValueChangedFcn",@(src, event)updateDfIDFcn(src, event, nexObj.nexon, nexObj));
    %% PLOT
    nexObj.Figure.panel0.tiles.t = tiledlayout(nexObj.Figure.panel0.ph,1,1);
    nexObj.Figure.panel0.tiles.ax = nexttile(nexObj.Figure.panel0.tiles.t);
    % [l, p] = boundedline(nexObj.Figure.panel1.tiles.Axes.(nexObj.classID),[nan],[nan],[nan],"-b","alpha");
    % ax_canvas= nexObj.Figure.panel0.tiles.ax;
    DF = nexObj.DF_postOp;
    axSel = string(nexObj.Figure.axSelDropDown.Value);
    % df_phase_slice = squeeze(DF.df(1, 1,:))';
    df_slice = sliceDF(DF.df, DF.ptr, axSel);
    if isfield(DF,"sem")
        sem_slice = sliceDF(DF.sem, DF.ptr, axSel);
    else
        sem_slice = zeros(1,size(df_slice,2));
    end
    t_axis = DF.ax.t;    
    % CANVAS
    [l, p] = plotWithSEM(nexObj.Figure.panel0.tiles.ax, t_axis, df_slice, sem_slice, [1,1,1],[]);
    % nexObj.Figure.panel1.tiles.graphics.(sprintf("%s_canvas_l",nexObj.classID)) = l;
    % nexObj.Figure.panel1.tiles.graphics.(sprintf("%s_canvas_p",nexObj.classID)) = p;
    nexObj.Figure.panel0.tiles.graphics.("canvas_l") = l;
    nexObj.Figure.panel0.tiles.graphics.("canvas_p") = p;
    % tIdx = nexObj.Origin.frameNum / nexObj.Origin.Fs - nexObj.Origin.preBufferLen;
    % tIdx = nexObj.Origin.frameNum / nexObj.Origin.Fs - nexObj.Origin.preBufferLen;
    % nexObj.Figure.panel1.tiles.graphics.(sprintf("%s_xLine_time",nexObj.classID)) = xline(ax_canvas,tIdx,"Color",nexObj.nexon.settings.Colors.cyberGreen);
    % XLINE
    % frame tracker
    % nexObj.Figure.panel0.tiles.graphics.(("xLine_frame")) = xline(ax_canvas,tIdx,"Color",nexObj.nexon.settings.Colors.cyberGreen);
    % event marker(s)
    % graphics_eventMarkers = nex_generateEventMarkers(nexObj, ax_canvas);
    % apply time-idx values
    % graphics_eventMarkers = nex_setMarkerValue()
    % merge graphics

    % color mapping
    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);
    colorAx_green(nexObj.Figure.panel0.tiles.ax);
    % 
end