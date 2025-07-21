function nexVisualization_spectroGraph_specs(nexObj, args)

    % CFG HEADER
    chanSel = args.chanSel; % default = 1
    freqSel = args.freqSel; % default = 1

    numIDParts_base=3;
    alphaVal=0.6;
    color_single = [1,1,1];
    % CASES:
    % 1) single trial
    % 2) avg but only for current phase
    % 3) avg for multiple phases
    if isempty((nexObj.DF_postOp.df)) % stable for now
        nexObj.DF_postOp = nexObj.DF;
    end
    DF = nexObj.DF_postOp;
    specFields = fieldnames(DF.df);
    % draw tiles (if none yet)
    if ~isfield(nexObj.Figure.panel1,"tiles")
        nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,length(specFields),1);
        nexObj.Figure.panel1.tiles.graphics = struct;
        nexObj.Figure.panel1.tiles.Axes = struct;
    end
    list_legend = [];
    h_legend = [];
    % clear (zero-out) all existing graphics
    structfun(@(graph) nex_clearGraphics(graph), nexObj.Figure.panel1.tiles.graphics);
    if isfield(DF,"sem") % multi-trial vis
        AVG = dtsIO_readAVG(nexObj.Origin, DF.avgCfg);
        avgFields = convertCharsToStrings(fieldnames(AVG));
        for i = 1:length(avgFields)
            avgField = avgFields(i);
            list_legend = [list_legend, strrep(avgField,"_","-")];
            % phase color
            phaseLUT = nexObj.nexon.console.BASE.map_phase;
            idx_phase = find(strcmp(phaseLUT.phase,strrep(avgField,"_","-")));
            color = phaseLUT(idx_phase,:).color;
            specFields = convertCharsToStrings(fieldnames(DF.df));
            for j = 1:length(specFields)                
                specField = specFields(j);
                axID = sprintf("%s_%s",nexObj.classID,specField);
                ax_canvas = nexObj.Figure.panel1.tiles.Axes.(axID);
                if j==1
                    axis=ax_canvas;
                end
                title(ax_canvas,specField,"Color",nexObj.nexon.settings.Colors.cyberGreen);
                % subtitle(ax_canvas,specField);
                ID_l_specPhase = sprintf("%s_canvas_l_%s_%s",nexObj.classID, specField, strrep(avgField,"_","x"));
                ID_p_specPhase = sprintf("%s_canvas_p_%s_%s",nexObj.classID, specField, strrep(avgField,"_","x"));
                df_specPhase = AVG.(avgField).df.(specField);
                if all(df_specPhase==0) & isscalar(df_specPhase)
                    continue
                end
                sem_specPhase = AVG.(avgField).sem.(specField);
                df_specPhase_slice = squeeze(df_specPhase(chanSel, freqSel,:))';
                sem_specPhase_slice = squeeze(sem_specPhase(chanSel, freqSel,:))';                
                t_axis = AVG.(avgField).ax.t(1:size(df_specPhase_slice,2));
                % handle pre/non-pre-existing canvas
                isSubFields = isfield(nexObj.Figure.panel1.tiles.graphics,(ID_l_specPhase)) && isfield(nexObj.Figure.panel1.tiles.graphics,(ID_p_specPhase));
                try
                    isValid= isvalid(nexObj.Figure.panel1.tiles.graphics.(ID_l_specPhase)) && isvalid(nexObj.Figure.panel1.tiles.graphics.(ID_p_specPhase));
                catch
                    isValid=0;
                end
                if isSubFields && isValid
                    l_phase = nexObj.Figure.panel1.tiles.graphics.(ID_l_specPhase);
                    p_phase = nexObj.Figure.panel1.tiles.graphics.(ID_p_specPhase);
                    nex_updateBoundedLineData(l_phase, p_phase, t_axis, df_specPhase_slice, sem_specPhase_slice, (color), alphaVal);                    
                else % generate new
                    [l_phase, p_phase] = plotWithSEM(ax_canvas,t_axis,df_specPhase_slice,sem_specPhase_slice,hex2rgb(color),alphaVal);
                    colorAx_green(ax_canvas);                    
                    % add graphics handles to figure tree
                    nexObj.Figure.panel1.tiles.graphics.(ID_l_specPhase) = l_phase;
                    nexObj.Figure.panel1.tiles.graphics.(ID_p_specPhase) = p_phase;
                end                
            end            
            h_legend = [h_legend, l_phase];
        end
    else % single trial vis
        specFields = convertCharsToStrings(fieldnames(DF.df));
        for j = 1:length(specFields)
            specField = specFields(j);
            axID = sprintf("%s_%s",nexObj.classID,specField);
            df_spec = DF.df.(specField);
            df_spec_slice = squeeze(df_spec(chanSel, freqSel,:))';
            t_axis = DF.ax.t(1:size(df_spec_slice,2));
            % axis ID
            if ~isfield(nexObj.Figure.panel1.tiles.Axes,(axID))
                ax_canvas = nexttile(nexObj.Figure.panel1.tiles.t);
                nexObj.Figure.panel1.tiles.Axes.(axID) = ax_canvas;
            else
                ax_canvas = nexObj.Figure.panel1.tiles.Axes.(axID);
            end
            if j==1
                axis=ax_canvas;
            end
            title(ax_canvas,specField,"Color",nexObj.nexon.settings.Colors.cyberGreen);
            % graphics ID
            ID_l_spec = sprintf("%s_canvas_l_%s",nexObj.classID, specField);
            % handle pre/non-pre-existing canvas (check if  exists and is
            % valid)
            isSubField = isfield(nexObj.Figure.panel1.tiles.graphics,ID_l_spec);
            try
                isValid = isvalid(nexObj.Figure.panel1.tiles.graphics.(ID_l_spec));
            catch
                isValid=0;
            end
            if isSubField && isValid
                l_spec = nexObj.Figure.panel1.tiles.graphics.(ID_l_spec);
                nex_updateBoundedLineData(l_spec, [], t_axis, df_spec_slice, [], [], alphaVal);
            else % generate new
                l_spec = plotWithSEM(ax_canvas, t_axis, df_spec_slice, [], color_single, alphaVal);
                colorAx_green(ax_canvas);
                % add event Markers
                nexObj.Figure.panel1.tiles.graphics.(sprintf("eventMarkers_%s",specField)) = nex_generateEventMarkers(nexObj, ax_canvas);
                % add graphcis handles to figure tree
                nexObj.Figure.panel1.tiles.graphics.(ID_l_spec) = l_spec;
            end
        end
    end
    % TITLE
    chanBinType = nexObj.Origin.pMap_chans.binType;
    [binEdges, binIDs_chans] = nexObj.Origin.pMap_chans.getBinEdges;
    freqBinType = nexObj.Origin.pMap_freqs.binType;            
    [binEdges, binIDs_freqs] = nexObj.Origin.pMap_freqs.getBinEdges;
    binID_chans = binIDs_chans(chanSel);
    binID_freqs = binIDs_freqs(freqSel);
    titleText = sprintf("%s: %s; %s: %s", chanBinType, binID_chans, freqBinType, binID_freqs);
    title(axis, titleText,"Color",nexObj.nexon.settings.Colors.cyberGreen);
    % legend
    if ~isempty(list_legend)
        lgd = legend(axis, h_legend, list_legend);
        lgd.TextColor = nexObj.nexon.settings.Colors.cyberGreen;
        lgd.EdgeColor = 'none';        % No border
        % lgd.Color = [0 0 0];           % black background
    end
end