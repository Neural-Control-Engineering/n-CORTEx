function nexVisualization_waterfall(nexObj, args)

    % CFG HEADER
    alphaVal          = args.alphaVal;          % default = 0.15
    lineWidth         = args.lineWidth;         % default = 1.5
    spacingMultiplier = args.spacingMultiplier; % default = 1.0
    component         = args.component;         % default = 'radial'
    scale             = args.scale;             % default = 'linear'
    maxDisplayPts     = args.maxDisplayPts;     % default = Inf

    % Guard
    DFp = nexObj.DF_postOp;
    if isempty(DFp) ...
            || (~isstruct(DFp) && ~isa(DFp, 'nexObj_DF')) ...
            || isempty(DFp.df)
        return;
    end

    ax = nexObj.Figure.panel0.tiles.ax;
    C  = nexObj.nexon.settings.Colors;
    GREEN = C.cyberGreen;
    if ischar(GREEN) || isstring(GREEN), GREEN = nexVis_hexToRGB(GREEN); end

    % Read domain selections
    domSel = nex_returnSelectionMask(nexObj.collector.Domain);
    d1Vals = string(domSel.D1);
    d2Vals = string(domSel.D2);
    if isempty(d1Vals) || isequal(d1Vals(1), ""), return; end
    xKey     = d1Vals(1);
    stackKey = "";
    if ~isempty(d2Vals) && ~isequal(d2Vals(1), "")
        stackKey = d2Vals(1);
    end

    srcKey      = nexObj.getCurrentSRC();
    isResultSRC = ~strcmp(srcKey, 'DTS') && ~strcmp(srcKey, 'DF') && isfield(nexObj.RESULTS, srcKey);

    ptrBus  = nexObj.collector.Pointer;
    viewSel = nex_returnSelectionMask(nexObj.collector.View);
    clrCols = string(viewSel.CLR);
    clrCols = clrCols(clrCols ~= "");

    % Sync ptrBus → ptr.indices once before extraction (skip during animation
    % so stepAnimate's ptr.value drives the frame, not the pinned bus index)
    if ~isResultSRC && isprop(nexObj, 'player') && ~isempty(nexObj.player) ...
            && strcmp(nexObj.player.Running, 'off')
        nexOp_syncPtrFromBus(nexObj.DF_postOp.ptr, ptrBus);
    end

    % Compute shared y-spacing from first / only DF
    if ~isResultSRC
        [allTraces, ~, ~] = nexVis_extractD1D2( ...
            nexVis_transformDF(nexObj.DF_postOp, component, scale), xKey, stackKey, ptrBus);
    else
        RESULT   = nexObj.RESULTS.(srcKey);
        rowIdx   = nexObj.filterResultsByVW(RESULT, viewSel.VW);
        firstRow = nexVis_transformDF(nexVis_rowToDF(RESULT, rowIdx(1)), component, scale);
        firstRow.ptr = nexOp_syncPtrFromBus(firstRow.ptr, ptrBus);
        [allTraces, ~, ~] = nexVis_extractD1D2(firstRow, xKey, stackKey, ptrBus);
    end
    ySpacing = nexVis_computeSpacing(allTraces, spacingMultiplier);

    % Redraw
    cla(ax);
    hold(ax, 'on');

    h_legend   = gobjects(0);
    lbl_legend = string.empty;

    if ~isResultSRC
        [traces, sems, xAxis] = nexVis_extractD1D2( ...
            nexVis_transformDF(nexObj.DF_postOp, component, scale), xKey, stackKey, ptrBus);
        nT = numel(traces);
        [C_traces, axLabels] = nexObj.resolveCLRColors(nexObj.DF_postOp, clrCols, nT);

        % Drop stacked traces that are entirely NaN — e.g. after REG
        % cross-session canonicalization (nexOp_alignCoAxes), most
        % canonical stack positions are legitimately never-recorded for
        % this DF and come back all-NaN; plotting them adds invisible
        % lines and can leave the view looking empty when only a few
        % positions actually have data. traces/sems/C_traces/axLabels are
        % all still positionally aligned at this point (same nT), so
        % filtering all four together here keeps them aligned rather than
        % risking desync by filtering nexVis_extractD1D2's output
        % independently of resolveCLRColors'.
        keepMask = ~cellfun(@(t) all(isnan(t)), traces);
        traces   = traces(keepMask);
        sems     = sems(keepMask);
        C_traces = C_traces(keepMask, :);
        if ~isempty(axLabels) && numel(axLabels) == numel(keepMask)
            axLabels = axLabels(keepMask);
        end

        h_all = wtfl_drawGroup(ax, xAxis, traces, sems, ySpacing, C_traces, alphaVal, lineWidth, maxDisplayPts);
        if ~isempty(axLabels)
            h_v = h_all(isvalid(h_all));
            nL  = min(numel(h_v), numel(axLabels));
            if nL > 0, h_legend = h_v(1:nL); lbl_legend = axLabels(1:nL); end
        end
    else
        [rowLabels, ~] = nexVis_rowLabels(RESULT, rowIdx);
        [rowBaseColors, axClrCols] = nexObj.splitResultsColors(RESULT, rowIdx, clrCols);

        % Union keep-mask across every overlaid row — a canonical stack
        % position is dropped only when EVERY row is all-NaN there. Each
        % row filtering its OWN NaN positions independently would compact
        % that row's surviving indices differently per row, so the same
        % canonical channel/unit would land at a different (i-1)*ySpacing
        % offset in different overlaid groups even though ySpacing itself
        % is shared. Only the (cheap) trace extraction is repeated here —
        % color/legend work happens once per row in the main loop below.
        unionKeepMask = [];
        for gi0 = 1:numel(rowIdx)
            DF_g0 = nexVis_transformDF(nexVis_rowToDF(RESULT, rowIdx(gi0)), component, scale);
            DF_g0.ptr = nexOp_syncPtrFromBus(DF_g0.ptr, ptrBus);
            [traces0, ~, ~] = nexVis_extractD1D2(DF_g0, xKey, stackKey, ptrBus);
            rowMask = ~cellfun(@(t) all(isnan(t)), traces0);
            if isempty(unionKeepMask)
                unionKeepMask = rowMask;
            else
                n = max(numel(unionKeepMask), numel(rowMask));
                unionKeepMask(end+1:n) = false; rowMask(end+1:n) = false; %#ok<AGROW>
                unionKeepMask = unionKeepMask | rowMask;
            end
        end

        axLegendDone = false;
        for gi = 1:numel(rowIdx)
            DF_g = nexVis_transformDF(nexVis_rowToDF(RESULT, rowIdx(gi)), component, scale);
            DF_g.ptr = nexOp_syncPtrFromBus(DF_g.ptr, ptrBus);
            [traces, sems, xAxis] = nexVis_extractD1D2(DF_g, xKey, stackKey, ptrBus);
            nT = numel(traces);
            [C_traces, axLabels] = nexObj.resolveCLRColors(DF_g, axClrCols, nT);
            C_traces = nexVis_blendColors(C_traces, axClrCols, rowBaseColors, gi, nT);

            % Drop all-NaN stacked traces using the UNION mask computed
            % above (not this row's own NaN pattern) — see that block's
            % comment for why: keeps a given canonical position at the
            % same stack index, and therefore the same y-offset, across
            % every overlaid row. traces/sems/C_traces/axLabels are still
            % positionally aligned here (same nT), so filtering all four
            % together keeps them aligned rather than risking desync.
            keepMask = unionKeepMask;
            if numel(keepMask) ~= numel(traces)
                keepMask(end+1:numel(traces)) = false;
                keepMask = keepMask(1:numel(traces));
            end
            traces   = traces(keepMask);
            sems     = sems(keepMask);
            C_traces = C_traces(keepMask, :);
            if ~isempty(axLabels) && numel(axLabels) == numel(keepMask)
                axLabels = axLabels(keepMask);
            end

            h_all = wtfl_drawGroup(ax, xAxis, traces, sems, ySpacing, C_traces, alphaVal, lineWidth, maxDisplayPts);

            if ~isempty(axLabels) && ~axLegendDone
                h_v = h_all(isvalid(h_all));
                nL  = min(numel(h_v), numel(axLabels));
                if nL > 0
                    h_legend = h_v(1:nL); lbl_legend = axLabels(1:nL); axLegendDone = true;
                end
            elseif isempty(axLabels)
                h_v = h_all(isvalid(h_all));
                if ~isempty(h_v)
                    h_legend(end+1)   = h_v(1);         %#ok<AGROW>
                    lbl_legend(end+1) = rowLabels(gi);  %#ok<AGROW>
                end
            end
        end
    end

    hold(ax, 'off');
    colorAx_green(ax);
    xlabel(ax, char(xKey), 'Color', C.cyberGreen);
    if ~isequal(stackKey, "")
        ylabel(ax, char(stackKey), 'Color', C.cyberGreen);
    end
    zlabel(ax, wtfl_valueLabel(component, scale), 'Color', C.cyberGreen);

    if ~isempty(h_legend)
        lgd = legend(ax, h_legend, cellstr(lbl_legend), 'Interpreter', 'none');
        nexVis_legendStyle(lgd, GREEN);
    else
        legend(ax, 'off');
    end
    % view(ax, -30, 30);
end

% ── Draw (stays local — specific to waterfall's 3-D plot3/surf layout) ───────

function h = wtfl_drawGroup(ax, xAxis, traces, sems, ySpacing, C, alphaVal, lineWidth, maxDisplayPts)
    if nargin < 9 || isempty(maxDisplayPts) || ~isfinite(maxDisplayPts)
        maxDisplayPts = Inf;
    end
    h       = gobjects(0);
    nTraces = numel(traces);
    x       = double(xAxis(:)');
    L       = numel(x);

    % Decimate to maxDisplayPts
    if isfinite(maxDisplayPts) && L > maxDisplayPts
        step = ceil(L / maxDisplayPts);
        x    = x(1:step:end);
        L    = numel(x);
    end

    for i = 1:nTraces
        z   = double(traces{i}(:)');
        s   = double(sems{i}(:)');
        n   = min([L, numel(z), numel(s)]);
        if n == 0, continue; end
        x_i = x(1:n);
        z_i = z(1:n);
        s_i = s(1:n);
        y_i = (i - 1) * ySpacing;
        c   = C(min(i, size(C, 1)), :);

        lh = plot3(ax, x_i, y_i * ones(1,n), z_i, '-', ...
            'Color',     c, ...
            'LineWidth', lineWidth);
        h(end+1) = lh; %#ok<AGROW>

        if any(s_i > 0)
            x2 = [x_i; x_i];
            y2 = y_i * ones(2, n);
            z2 = [z_i + s_i; z_i - s_i];
            surf(ax, x2, y2, z2, ...
                'FaceColor', c, ...
                'FaceAlpha', alphaVal, ...
                'EdgeColor', 'none');
        end
    end
end

function lbl = wtfl_valueLabel(component, scale)
    switch lower(char(component))
        case 'angular', lbl = 'phase (rad)';
        otherwise
            if strcmpi(scale, 'log')
                lbl = 'magnitude (dB)';
            else
                lbl = 'magnitude';
            end
    end
end
