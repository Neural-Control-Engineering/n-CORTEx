function nexVisualization_monoGraph(nexObj, args)

    % CFG HEADER
    alphaVal = args.alphaVal; % default = 0.6

    numIDParts_base=2;    
    % alphaVal = 0.6;
    % CASES:
    % 1) single trial
    % 2) avg but only for current phase
    % 3) avg for multiple phases
    DF = nexObj.DF_postOp;
    % df_slice = DF.df(chanSel, freqSel,:);
    % plot timecourse 
    % 1: with sem shading if applicable
    % 2: with other averaged if applicable
    axis = nexObj.Figure.panel0.tiles.ax;
    list_legend = [];
    h_legend = [];
    if isfield(DF,"sem")
        if isfield(DF,"avgCfg")
            % clear all existing base graphics
            graphics_current = struct2cell(nexObj.Figure.panel0.tiles.graphics);
            ID_graphics_current = (fieldnames(nexObj.Figure.panel0.tiles.graphics));
            ID_graphics_parts = cellfun(@(ID) split(string(ID),"_"),ID_graphics_current,"UniformOutput",false);
            isBaseGraphics = cellfun(@(IDparts) size(IDparts,1)==numIDParts_base,ID_graphics_parts,"UniformOutput",true);
            graphics_base = graphics_current(isBaseGraphics);
            ID_graphics_base = convertCharsToStrings(ID_graphics_current(isBaseGraphics));
            % cellfun(@(graphic, ID_graphic) nex_removeGraphic(nexObj, graphic, ID_graphic, "xLine"), graphics_current, ID_graphics_current,"UniformOutput",false);
            % empty the visual data for the base figure
            % ID_l_phase_base = ID_graphics_base(contains(ID_graphics_base,"l"));
            l_phase_base = graphics_base{contains(ID_graphics_base,"_l")};
            p_phase_base = graphics_base{contains(ID_graphics_base,"_p")};
            t_axis = DF.ax.t;
            nex_updateBoundedLineData(l_phase_base, p_phase_base, t_axis, nan(size(t_axis)), nan(size(t_axis)),[],[]);
            % look for matching averages (in Origin.UserData)
            AVG = dtsIO_readAVG(nexObj.Origin, DF.avgCfg);
            avgFields = convertCharsToStrings(fieldnames(AVG));       
            % UPDATE PLOT  
            list_legend=[];
            list_color = [];
            for i = 1:length(avgFields)
                avgField = avgFields(i);                
                % phase color
                % phaseLUT = nexObj.nexon.console.BASE.map_phase.Map;
                phaseLUT = nexObj.nexon.console.BASE.map_phase;
                idx_phase = find(strcmp(phaseLUT.phase,strrep(avgField,"_","-")));
                color = phaseLUT(idx_phase,:).color;
                list_legend = [list_legend, strrep(avgField,"_","-")];
                list_color = [list_color, color];
                ID_l_phase = sprintf("%s_canvas_l_%s", nexObj.classID, strrep(avgField,"_","x"));                
                ID_p_phase = sprintf("%s_canvas_p_%s",nexObj.classID, strrep(avgField,"_","x"));
                df_phase = AVG.(avgField).df;
                sem_phase = AVG.(avgField).sem;
                % SLICE DF
                % df_phase_slice = squeeze(df_phase(chanSel, freqSel,:))';
                % t_axis = AVG.(avgField).ax.t(1:size(df_phase_slice,2));
                % sem_phase_slice = squeeze(sem_phase(chanSel, freqSel,:))'; 
                axSel = nexObj.Figure.axSelDropDown.Value;         
                ptr = DF.ptr;
                df_phase_slice = sliceDF(df_phase, ptr, axSel, "range");
                sem_phase_slice = sliceDF(sem_phase, ptr, axSel,"range");
                isSubFields = isfield( nexObj.Figure.panel0.tiles.graphics,ID_l_phase) && isfield( nexObj.Figure.panel0.tiles.graphics,ID_p_phase);
                try
                    isValid = isvalid( nexObj.Figure.panel0.tiles.graphics.(ID_l_phase)) && isvalid( nexObj.Figure.panel0.tiles.graphics.(ID_p_phase));
                catch
                    isValid = 0;
                end
                if isSubFields && isValid
                    l_phase = nexObj.Figure.panel0.tiles.graphics.(ID_l_phase);
                    p_phase = nexObj.Figure.panel0.tiles.graphics.(ID_p_phase);
                    nex_updateBoundedLineData(l_phase, p_phase, t_axis, df_phase_slice, sem_phase_slice, color,alphaVal);
                else % generate new                                       
                    [l_phase, p_phase] = plotWithSEM(axis,t_axis,df_phase_slice,sem_phase_slice,hex2rgb(color),alphaVal);
                    colorAx_green(axis);                   
                    % add graphics handles to figure tree
                    nexObj.Figure.panel0.tiles.graphics.(ID_l_phase) = l_phase;
                    nexObj.Figure.panel0.tiles.graphics.(ID_p_phase) = p_phase;                    
                end
                h_legend = [h_legend, l_phase];
            end
        end
    else % single trial vis
        % format plot data
        ID_line = sprintf("canvas_l");
        ID_patch = sprintf("canvas_p");
        df = DF.df;                     
        ptr = DF.ptr;
        % slice dataframe
        axSel = nexObj.Figure.axSelDropDown.Value;                
        df_slice = sliceDF(df, ptr, axSel, "range");
        % t_axis = DF.ax.t(1:size(df_slice,2));
        t_axis = DF.ax.(axSel);
        sem_slice = nan(size(df_slice));                     
        % UPDATE PLOT
        if isfield( nexObj.Figure.panel0.tiles.graphics,ID_line) && isfield( nexObj.Figure.panel0.tiles.graphics,ID_patch) % graphics sub field exists
            line = nexObj.Figure.panel0.tiles.graphics.(ID_line);
            patch = nexObj.Figure.panel0.tiles.graphics.(ID_patch);
            % df = DF.df;                
            % df_slice = squeeze(df(chanSel, freqSel,:))';
            % t_axis = DF.ax.t(1:size(df_slice,2));
            % sem_slice = nan(size(df_slice));
            nex_updateBoundedLineData(line, patch, t_axis, df_slice, sem_slice,[],[]);
        else                
            [l_phase, p_phase] = plotWithSEM(axis,t_axis,df_slice,sem_slice,[],[]);
            colorAx_green(axis);                   
            % add graphics handles to figure tree
            nexObj.Figure.panel0.tiles.graphics.(ID_line) = l_phase;
            nexObj.Figure.panel0.tiles.graphics.(ID_phase) = p_phase;                    
        end    
    end    

    % TITLE
    % chanBinType = nexObj.Origin.pMap.pMap_chans.binType;    
    % [binEdges, binIDs_chans] = nexObj.Origin.pMap.pMap_chans.getBinEdges(nexObj.Origin.DF_postOp.ax.chans);
    % freqBinType = nexObj.Origin.pMap.pMap_freqs.binType;            
    % [binEdges, binIDs_freqs] = nexObj.Origin.pMap.pMap_freqs.getBinEdges(nexObj.Origin.DF_postOp.ax.f);
    % binID_chans = binIDs_chans(chanSel);
    % binID_freqs = binIDs_freqs(freqSel);
    % % region inference
    % binID_alpha = split(binID_chans,"--"); binID_alpha=binID_alpha(1);binID_num = str2double(binID_alpha);
    % region = convertCharsToStrings(nexObj.Origin.regMap(cell2mat(nexObj.Origin.regMap.channel==binID_num),:).region);
    % % title label
    % titleText = sprintf("%s, %s: %s; %s: %s", region, chanBinType, binID_chans, freqBinType, binID_freqs);
    % title(axis, titleText,"Color",nexObj.nexon.settings.Colors.cyberGreen);
    % % legend
    % if ~isempty(list_legend)
    %     lgd = legend(axis, h_legend, list_legend);
    %     lgd.TextColor = nexObj.nexon.settings.Colors.cyberGreen;
    %     lgd.EdgeColor = 'none';        % No border
    %     % lgd.Color = [0 0 0];           % black background
    % end   

end