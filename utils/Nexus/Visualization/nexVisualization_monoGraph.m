function nexVisualization_monoGraph(nexObj, args)
    % CFG HEADER
    alphaVal  = args.alphaVal;   % default = 0.6
    yLim_high = args.yLim_high;  % default = 1
    yLim_low  = args.yLim_low;   % default = -1

    ax    = nexObj.Figure.panel0.tiles.ax;
    axSel = nexObj.Figure.axSelDropDown.Value;
    GREEN = nexObj.nexon.settings.Colors.cyberGreen;

    srcKey   = nexObj.getCurrentSRC();
    viewSel  = nex_returnSelectionMask(nexObj.collector.View);
    vwGroups = string(viewSel.VW);
    clrCols  = string(viewSel.CLR);
    clrCols  = clrCols(clrCols ~= "");

    useResults = ~strcmp(srcKey, 'DF') ...
        && isfield(nexObj.RESULTS, srcKey) ...
        && ~isempty(nexObj.RESULTS.(srcKey)) ...
        && ~isequal(vwGroups, "") ...
        && ~isempty(vwGroups);

    % Set scale before rendering so patches are created in the correct mode
    if strcmp(axSel, 'f'), ax.XScale = 'log'; else, ax.XScale = 'linear'; end

    %% Clear base canvas when switching to RESULTS mode
    gfx = nexObj.Figure.panel0.tiles.graphics;
    if useResults && isfield(gfx, 'canvas_l') && isvalid(gfx.canvas_l)
        set(gfx.canvas_l, 'XData', NaN, 'YData', NaN);
    end

    if useResults
        %% ── RESULTS-based multi-group rendering ──────────────────────────
        RESULT       = nexObj.RESULTS.(srcKey);
        DF_STRUCT    = ["df","ax","ptr","sem"];
        groupCols    = string(RESULT.Properties.VariableNames);
        groupCols    = groupCols(~ismember(groupCols, DF_STRUCT));
        labelCols    = groupCols;

        matchingRows = nexObj.filterResultsByVW(RESULT, vwGroups)';
        nMatch       = numel(matchingRows);

        % Composite label per row: join group column values with ' | '
        rowLabels  = strings(nMatch, 1);
        activeFlds = strings(nMatch, 1);
        for ri = 1:nMatch
            r     = matchingRows(ri);
            parts = arrayfun(@(c) string(RESULT.(char(groupCols(c)))(r)), ...
                1:numel(groupCols), 'UniformOutput', false);
            rowLabels(ri)  = strjoin([parts{:}], ' | ');
            activeFlds(ri) = string(matlab.lang.makeValidName(char(rowLabels(ri))));
        end

        % Pre-compute per-row colors across all matching rows so that
        % resolveGroupColors sees the full spread of each column's values.
        if ~isempty(clrCols)
            rowColors = nexObj.resolveGroupColors(RESULT(matchingRows,:), clrCols);
        elseif nMatch > 1
            rowColors = nexVis_hsvSpread(nMatch);
        else
            rowColors = repmat(GREEN, nMatch, 1);
        end

        h_legend   = gobjects(0);
        lbl_legend = string.empty;
        ptr_DF     = nexObj.DF_postOp.ptr;

        for ri = 1:nMatch
            r    = matchingRows(ri);
            df_g  = RESULT.df{r};
            ax_g  = RESULT.ax{r};
            sem_g = RESULT.sem{r};
            ptr_g = RESULT.ptr{r};

            ptr_use = ptr_DF;
            if isstruct(ptr_g) && isfield(ptr_g, axSel) && isfield(ptr_DF, axSel)
                ptr_use.(axSel).range = ptr_g.(axSel).range;
            end
            df_slice  = nexOp_permuteLong2second(squeeze(sliceDF(df_g,  ptr_use, axSel, "range")));
            sem_slice = nexOp_permuteLong2second(squeeze(sliceDF(sem_g, ptr_use, axSel, "range")));
            t_ax   = ax_g.(axSel);
            if strcmp(axSel, 'f')
                posF = t_ax > 0;
                t_ax = t_ax(posF); df_slice = df_slice(posF); sem_slice = sem_slice(posF);
            end
            clr = rowColors(ri,:);
            hexStr = sprintf('%02X%02X%02X', round(clr * 255));

            fld  = char(activeFlds(ri));
            ID_l = fld + "_l";
            ID_p = fld + "_p";

            hasH = isfield(nexObj.Figure.panel0.tiles.graphics, ID_l) ...
                && isfield(nexObj.Figure.panel0.tiles.graphics, ID_p);
            try, isValid = hasH && isvalid(nexObj.Figure.panel0.tiles.graphics.(ID_l)); catch, isValid = false; end

            if isValid
                nex_updateBoundedLineData( ...
                    nexObj.Figure.panel0.tiles.graphics.(ID_l), ...
                    nexObj.Figure.panel0.tiles.graphics.(ID_p), ...
                    t_ax, df_slice, sem_slice, string(hexStr), alphaVal);
            else
                [l_g, p_g] = plotWithSEM(ax, t_ax, df_slice, sem_slice, clr, alphaVal);
                colorAx_green(ax);
                nexObj.Figure.panel0.tiles.graphics.(ID_l) = l_g;
                nexObj.Figure.panel0.tiles.graphics.(ID_p) = p_g;
            end
            h_legend(end+1)   = nexObj.Figure.panel0.tiles.graphics.(ID_l); %#ok<AGROW>
            lbl_legend(end+1) = rowLabels(ri); %#ok<AGROW>
        end

        % NaN-clear handles for groups no longer selected
        gfx      = nexObj.Figure.panel0.tiles.graphics;
        allFlds  = string(fieldnames(gfx))';
        lineFlds = allFlds(endsWith(allFlds, "_l") & allFlds ~= "canvas_l");
        for fld = lineFlds
            baseName = extractBefore(fld, strlength(fld) - 1);
            if ismember(baseName, activeFlds), continue; end
            hl = gfx.(fld);
            if isvalid(hl), set(hl, 'XData', NaN, 'YData', NaN); end
            pFld = baseName + "_p";
            if isfield(gfx, pFld)
                hp = gfx.(pFld);
                if isvalid(hp)
                    set(hp, 'XData', NaN, 'YData', NaN, 'Vertices', [NaN NaN], 'Faces', 1);
                end
            end
        end

        % Legend
        if ~isempty(h_legend)
            lgd = legend(ax, h_legend, cellstr(lbl_legend), 'Interpreter', 'none');
            lgd.TextColor = GREEN;
            lgd.Color     = [0 0 0];
            lgd.EdgeColor = GREEN;
            lgd.FontSize  = 16;
        end

    else
        %% ── Single-DF rendering ──────────────────────────────────────────
        DF  = nexObj.DF_postOp;
        ptr = DF.ptr;
        df_slice  = nexOp_permuteLong2second(squeeze(sliceDF(DF.df, ptr, axSel, "range")));
        t_axis    = DF.ax.(axSel);
        sem_slice = nan(size(df_slice));
        if strcmp(axSel, 'f')
            posF = t_axis > 0;
            t_axis = t_axis(posF); df_slice = df_slice(posF); sem_slice = sem_slice(posF);
        end

        if isfield(gfx, 'canvas_l') && isvalid(gfx.canvas_l)
            nex_updateBoundedLineData(gfx.canvas_l, gfx.canvas_p, t_axis, df_slice, sem_slice, [], []);
        else
            [l, p] = plotWithSEM(ax, t_axis, df_slice, sem_slice, [1,1,1], []);
            colorAx_green(ax);
            nexObj.Figure.panel0.tiles.graphics.canvas_l = l;
            nexObj.Figure.panel0.tiles.graphics.canvas_p = p;
        end
        legend(ax, 'off');
    end

    %% Axis limits + labels + ticks
    ax.YLim = [yLim_low, yLim_high];

    xlabel(ax, axSel, 'Color', GREEN);
    if isfield(nexObj.DF_postOp.ax, axSel)
        t_vals = double(nexObj.DF_postOp.ax.(axSel));
        if strcmp(axSel, 'f')
            t_vals = t_vals(t_vals > 0);
            lo = log10(min(t_vals));  hi = log10(max(t_vals));
            decades  = floor(lo) : ceil(hi);
            base125  = [1, 2, 5];
            tickCands = (10 .^ decades(:)) .* base125;
            tickCands = unique(tickCands(:));
            ax.XTick = tickCands(tickCands >= min(t_vals) & tickCands <= max(t_vals));
        else
            ax.XTick = linspace(min(t_vals), max(t_vals), 40);
        end
    end

    domain.F  = nexObj.dfID_source;
    domain.D1 = axSel;
    d2List    = fieldnames(nexObj.DF_postOp.ptr);
    domain.D2 = convertCharsToStrings(d2List(~strcmp(axSel, d2List)));
    nexObj.domain = domain;

    axTitle = nexTract_axisTitle(nexObj, nexObj.DF_postOp);
    title(ax, axTitle, "Color", GREEN);
end


function colors = nexVis_hsvSpread(n)
    hues   = linspace(0, 1, n + 1);  hues(end) = [];
    colors = arrayfun(@(h) hsv2rgb([h, 0.8, 0.9]), hues, 'UniformOutput', false);
    colors = vertcat(colors{:});
end
