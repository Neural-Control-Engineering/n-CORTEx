function nexFigure_spectroGraph(nexObj)
    %% DRAW PLOT
    nexObj.Figure.fh = uifigure("Position",[100,1260,650,250],"Color",[0,0,0]);   
    % plot panel
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,500,240],"BackgroundColor",[0,0,0]);
    % cfg panel
    nexObj.Figure.panel2.ph = uipanel(nexObj.Figure.fh,"Position",[510,5,135,240],"BackgroundColor",[0,0,0],"Scrollable","on");
    % nexObj.Figure.panel2.entryPanel = nexObj_cfgPanel(nexObj.nexon,nexObj,nexObj.Figure.panel2.ph,nexObj.opCfg.entryParams,);
    % opCfgEntryChangedFcn = str2func("opCfgEntryChanged");
    % nexObj.Figure.panel2 = nexObj_cfgPanel(nexObj.nexon,nexObj,nexObj.Figure.panel2,nexObj.opCfg.entryParams,opCfgEntryChangedFcn,[]);
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged");
    nexObj.Figure.panel2 = nexObj_cfgPanel_spinner(nexObj.nexon,nexObj,nexObj.Figure.panel2,nexObj.visCfg.entryParams,visCfgEntryChangedFcn,[]);
    % plot axes
    nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,1,1);
    nexObj.Figure.panel1.tiles.Axes.(nexObj.classID) = nexttile(nexObj.Figure.panel1.tiles.t);
    % [l, p] = boundedline(nexObj.Figure.panel1.tiles.Axes.(nexObj.classID),[nan],[nan],[nan],"-b","alpha");
    ax_canvas= nexObj.Figure.panel1.tiles.Axes.(nexObj.classID);
    DF = nexObj.DF;
    df_phase_slice = squeeze(DF.df(1, 1,:))';
    t_axis = DF.ax.t(1:size(df_phase_slice,2));
    sem_phase_slice = zeros(1,size(df_phase_slice,2));
    [l, p] = plotWithSEM(nexObj.Figure.panel1.tiles.Axes.(nexObj.classID), t_axis, df_phase_slice, sem_phase_slice, [], []);
    nexObj.Figure.panel1.tiles.graphics.(sprintf("%s_canvas_l",nexObj.classID)) = l;
    nexObj.Figure.panel1.tiles.graphics.(sprintf("%s_canvas_p",nexObj.classID)) = p;
    tIdx = nexObj.Origin.frameNum / nexObj.Origin.Fs - nexObj.Origin.preBufferLen;
    nexObj.Figure.panel1.tiles.graphics.(sprintf("%s_xLine",nexObj.classID)) = xline(ax_canvas,tIdx,"Color",nexObj.nexon.settings.Colors.cyberGreen);
    % color mapping
    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);
    colorAx_green(nexObj.Figure.panel1.tiles.Axes.(nexObj.classID));
    % 
end