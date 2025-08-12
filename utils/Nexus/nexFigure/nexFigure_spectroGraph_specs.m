function nexFigure_spectroGraph_specs(nexObj)
    %% DRAW PLOT
    nexObj.Figure.fh = uifigure("Position",[100,1260,650,1250],"Color",[0,0,0]);   
    % plot panel
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,500,1240],"BackgroundColor",[0,0,0]);
    % cfg panel
    nexObj.Figure.panel2.ph = uipanel(nexObj.Figure.fh,"Position",[510,5,135,1240],"BackgroundColor",[0,0,0],"Scrollable","on");
    % nexObj.Figure.panel2.entryPanel = nexObj_cfgPanel(nexObj.nexon,nexObj,nexObj.Figure.panel2.ph,nexObj.opCfg.entryParams,);
    % opCfgEntryChangedFcn = str2func("opCfgEntryChanged");
    % nexObj.Figure.panel2 = nexObj_cfgPanel(nexObj.nexon,nexObj,nexObj.Figure.panel2,nexObj.opCfg.entryParams,opCfgEntryChangedFcn,[]);
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged");
    entryFormArgs.entryHeightScaler=50;
    nexObj.Figure.panel2 = nexObj_cfgPanel_spinner(nexObj.nexon,nexObj,nexObj.Figure.panel2,nexObj.visCfg.entryParams,visCfgEntryChangedFcn,entryFormArgs);
    % plot axes (one for each spec)
    DF = nexObj.DF_postOp;
    if ~isempty(DF.df)
        specFields = fieldnames(DF.df);
        nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,length(specFields),1);    
        tIdx = nexObj.Origin.frameNum / nexObj.Origin.Fs - nexObj.Origin.preBufferLen;
        for i = 1:length(specFields)
            specField = specFields{i};
            % make an axis
            axID = sprintf("%s_%s", nexObj.classID, specField);
            nexObj.Figure.panel1.tiles.Axes.(axID) = nexttile(nexObj.Figure.panel1.tiles.t);
            ax_canvas = nexObj.Figure.panel1.tiles.Axes.(axID);
            % data slicing/formatting
            df_specPhase_slice = squeeze(DF.df.(specField)(1,1,:))';
            if isfield(DF,"sem")
                sem_specPhase_slice = squeeze(DF.sem.(specField)(1,1,:))';
            else
                sem_specPhase_slice = zeros(size(df_specPhase_slice));
            end        
            t_axis=DF.ax.t;
            [l_phase, p_phase] = plotWithSEM(ax_canvas, t_axis, df_specPhase_slice, sem_specPhase_slice,[],[]);
            if isfield(DF,"avgCfg")
                ID_phase=DF.avgCfg.phase;
            else
                ID_phase="single";
            end
            ID_l_specPhase=sprintf("%s_canvas_l_%s_%s", nexObj.classID,specField,strrep(ID_phase,"-","x"));
            ID_p_specPhase=sprintf("%s_canvas_p_%s_%s", nexObj.classID,specField,strrep(ID_phase,"-","x"));
            ID_xLine_specPhase=sprintf("%s_canvas_xLine_%s_%s",nexObj.classID,specField,strrep(ID_phase,"-","x"));
            nexObj.Figure.panel1.tiles.graphics.(ID_l_specPhase) = l_phase;
            nexObj.Figure.panel1.tiles.graphics.(ID_p_specPhase) = p_phase;
            nexObj.Figure.panel1.tiles.graphics.(ID_xLine_specPhase) = xline(ax_canvas, tIdx, "Color", nexObj.nexon.settings.Colors.cyberGreen);
            colorAx_green(nexObj.Figure.panel1.tiles.Axes.(axID));
        end    
    end
   
    % nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,1,1);
    % nexObj.Figure.panel1.tiles.Axes.(nexObj.classID) = nexttile(nexObj.Figure.panel1.tiles.t);
    % [l, p] = boundedline(nexObj.Figure.panel1.tiles.Axes.(nexObj.classID),[nan],[nan],[nan],"-b","alpha");
    % ax_canvas= nexObj.Figure.panel1.tiles.Axes.(nexObj.classID);
    
    % df_phase_slice = squeeze(DF.df(1, 1,:))';
    % t_axis = DF.ax.t(1:size(df_phase_slice,2));
    % sem_phase_slice = zeros(1,size(df_phase_slice,2));
    % [l, p] = plotWithSEM(nexObj.Figure.panel1.tiles.Axes.(nexObj.classID), t_axis, df_phase_slice, sem_phase_slice, [], []);
    % nexObj.Figure.panel1.tiles.graphics.(sprintf("%s_canvas_l",nexObj.classID)) = l;
    % nexObj.Figure.panel1.tiles.graphics.(sprintf("%s_canvas_p",nexObj.classID)) = p;
    % tIdx = nexObj.Origin.frameNum / nexObj.Origin.Fs - nexObj.Origin.preBufferLen;
    % nexObj.Figure.panel1.tiles.graphics.(sprintf("%s_xLine",nexObj.classID)) = xline(ax_canvas,tIdx,"Color",nexObj.nexon.settings.Colors.cyberGreen);
    % % color mapping
    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);
    % colorAx_green(nexObj.Figure.panel1.tiles.Axes.(nexObj.classID));
    % 
end