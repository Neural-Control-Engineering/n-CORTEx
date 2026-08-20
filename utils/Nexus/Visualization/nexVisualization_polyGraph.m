function nexVisualization_polyGraph(nexObj, args)

    % CFG HEADER
    spacingMultiplier = args.spacingMultiplier; % default = 1.2
    alphaVal  = args.alphaVal;  % default = 0.4
    lineWidth = args.lineWidth; % default = 1.5
    component = args.component; % default = 'radial'
    scale     = args.scale;     % default = 'linear'
    maxDisplayPts = args.maxDisplayPts; % default = Inf

    tTotal = tic;   % ── timing root ──────────────────────────────────────

    % Guard
    DFp = nexObj.DF_postOp;
    if isempty(DFp) ...
            || (~isstruct(DFp) && ~isa(DFp, 'nexObj_DF')) ...
            || isempty(DFp.df)
        return;
    end

    ax  = nexObj.Figure.panel0.tiles.ax;
    C   = nexObj.nexon.settings.Colors;

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

    GREEN = C.cyberGreen;
    if ischar(GREEN) || isstring(GREEN), GREEN = nexVis_hexToRGB(GREEN); end

    % Compute shared y-spacing from first / only DF
    t_setup = tic;
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
    ySpacing  = nexVis_computeSpacing(allTraces, spacingMultiplier);
    T_setup   = toc(t_setup);

    % Redraw
    cla(ax);
    hold(ax, 'on');

    h_legend   = gobjects(0);
    lbl_legend = string.empty;

    % Timing accumulators (RESULTS branch)
    T_rowToDF = 0;  T_transform = 0;  T_syncPtr = 0;
    T_extract = 0;  T_color     = 0;  T_draw    = 0;

    if ~isResultSRC
        % Sync ptrBus → ptr.indices (skip during animation so stepAnimate's
        % ptr.value drives the frame rather than the pinned bus index)
        if isprop(nexObj,'player')
            if ~isempty(nexObj.player)
                if strcmp(nexObj.player.Running, 'off')
                    nexOp_syncPtrFromBus(nexObj.DF_postOp.ptr, ptrBus);
                end
            end
        end

        t_ = tic;
        [traces, sems, xAxis] = nexVis_extractD1D2( ...
            nexVis_transformDF(nexObj.DF_postOp, component, scale), xKey, stackKey, ptrBus);
        T_transform = toc(t_);

        t_ = tic;
        nT = numel(traces);
        [C_traces, axLabels] = nexObj.resolveCLRColors(nexObj.DF_postOp, clrCols, nT);
        T_color = toc(t_);

        t_ = tic;
        h_all = pgph_drawGroup(ax, xAxis, traces, sems, ySpacing, C_traces, alphaVal, lineWidth, maxDisplayPts);
        T_draw = toc(t_);

        if ~isempty(axLabels)
            h_v = h_all(isvalid(h_all));
            nL  = min(numel(h_v), numel(axLabels));
            if nL > 0, h_legend = h_v(1:nL); lbl_legend = axLabels(1:nL); end
        end
    else
        [rowLabels, ~] = nexVis_rowLabels(RESULT, rowIdx);
        [rowBaseColors, axClrCols] = nexObj.splitResultsColors(RESULT, rowIdx, clrCols);

        axLegendDone = false;
        for gi = 1:numel(rowIdx)

            t_ = tic;
            raw = nexVis_rowToDF(RESULT, rowIdx(gi));
            T_rowToDF = T_rowToDF + toc(t_);

            t_ = tic;
            DF_g = nexVis_transformDF(raw, component, scale);
            T_transform = T_transform + toc(t_);

            t_ = tic;
            DF_g.ptr = nexOp_syncPtrFromBus(DF_g.ptr, ptrBus);
            T_syncPtr = T_syncPtr + toc(t_);

            t_ = tic;
            [traces, sems, xAxis] = nexVis_extractD1D2(DF_g, xKey, stackKey, ptrBus);
            T_extract = T_extract + toc(t_);

            nT = numel(traces);

            t_ = tic;
            [C_traces, axLabels] = nexObj.resolveCLRColors(DF_g, axClrCols, nT);
            C_traces = nexVis_blendColors(C_traces, axClrCols, rowBaseColors, gi, nT);
            T_color = T_color + toc(t_);

            t_ = tic;
            h_all = pgph_drawGroup(ax, xAxis, traces, sems, ySpacing, C_traces, alphaVal, lineWidth, maxDisplayPts);
            T_draw = T_draw + toc(t_);

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

    if ~isempty(h_legend)
        lgd = legend(ax, h_legend, cellstr(lbl_legend), 'Interpreter', 'none');
        nexVis_legendStyle(lgd, GREEN);
    else
        legend(ax, 'off');
    end

    % ── Timing report ────────────────────────────────────────────────────
    nR = 1;
    if isResultSRC, nR = numel(rowIdx); end
    t_render = tic;
    drawnow;
    T_render = toc(t_render);
    % fprintf('[polyGraph] setup=%.3fs  transform=%.3fs  syncPtr=%.3fs  extract=%.3fs  color=%.3fs  draw=%.3fs  render=%.3fs  TOTAL=%.3fs  (nRows=%d nTraces=%d)\n', ...
        % T_setup, T_transform, T_syncPtr, T_extract, T_color, T_draw, T_render, toc(tTotal), nR, nT);
end

% ── Draw (stays local — specific to polyGraph's 2-D stacked layout) ──────────

function h = pgph_drawGroup(ax, xAxis, traces, sems, ySpacing, C, alphaVal, lineWidth, maxDisplayPts)
% Draw N offset traces with SEM shading.
%
% Vectorized: one patch() for all SEM fills, one plot() for all lines.
% maxDisplayPts: decimate x-axis to this many points before rendering.
%   Inf (default) = no decimation; set to e.g. 800 for faster scans.
    if nargin < 9 || isempty(maxDisplayPts) || ~isfinite(maxDisplayPts)
        maxDisplayPts = Inf;
    end
    h       = gobjects(0);
    nTraces = numel(traces);
    if nTraces == 0, return; end

    xD = double(xAxis(:));
    L  = numel(xD);
    if L == 0, return; end   % empty x-axis (degenerate/empty trace) — nothing to draw
    if size(C, 1) == 1, C = repmat(C, nTraces, 1); end

    % Build offset Y and SEM S matrices  (L × nTraces)
    Y = zeros(L, nTraces);
    S = zeros(L, nTraces);
    for i = 1:nTraces
        t_i = double(traces{i}(:)');
        s_i = double(sems{i}(:)');
        n_i = min([L, numel(t_i), numel(s_i)]);
        if n_i < 1, continue; end
        Y(1:n_i, i) = t_i(1:n_i)' + (i - 1) * ySpacing;
        S(1:n_i, i) = s_i(1:n_i)';
    end

    % ── Decimate to maxDisplayPts ─────────────────────────────────────────
    if isfinite(maxDisplayPts) && L > maxDisplayPts
        step = ceil(L / maxDisplayPts);
        xD   = xD(1:step:end);
        Y    = Y(1:step:end, :);
        S    = S(1:step:end, :);
        L    = size(Y, 1);
    end

    % ── SEM fill: single patch, one face per trace ────────────────────────
    % xPoly / yPoly: 2L × nTraces — each column is a closed polygon
    xPoly = repmat([xD; flipud(xD)], 1, nTraces);
    yPoly = [Y + S; flipud(Y - S)];
    ph = patch(ax, xPoly, yPoly, 'w', 'EdgeColor', 'none', ...
               'FaceAlpha', double(alphaVal));
    ph.FaceVertexCData = C;       % nTraces × 3 truecolor, one per face
    ph.FaceColor       = 'flat';

    % ── Lines: single plot() via ColorOrder ───────────────────────────────
    % Setting ax.ColorOrder + ColorOrderIndex lets one plot() call draw
    % all N columns with per-column colors.  State is restored after.
    prevOrder = ax.ColorOrder;
    prevIdx   = ax.ColorOrderIndex;
    ax.ColorOrder      = C;
    ax.ColorOrderIndex = 1;
    lh = plot(ax, xD, Y, '-', 'LineWidth', lineWidth);
    ax.ColorOrder      = prevOrder;
    ax.ColorOrderIndex = prevIdx;

    h = lh(arrayfun(@isvalid, lh));
end
