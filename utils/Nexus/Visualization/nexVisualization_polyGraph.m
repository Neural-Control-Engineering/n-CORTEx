function nexVisualization_polyGraph(nexObj, args)

    % CFG HEADER
    spacingMultiplier = args.spacingMultiplier; % default = 1.2
    alphaVal  = args.alphaVal;  % default = 0.4
    lineWidth = args.lineWidth; % default = 1.5
    component = args.component; % default = 'radial'
    scale     = args.scale;     % default = 'linear'


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
    if ischar(GREEN) || isstring(GREEN), GREEN = pgph_toRGB(GREEN); end

    % Compute shared y-spacing from first / only DF
    if ~isResultSRC
        [allTraces, ~, ~] = pgph_extractD1D2( ...
            pgph_transformDF(nexObj.DF_postOp, component, scale), xKey, stackKey, ptrBus);
    else
        RESULT   = nexObj.RESULTS.(srcKey);
        rowIdx   = nexObj.filterResultsByVW(RESULT, viewSel.VW);
        firstRow = pgph_transformDF(pgph_rowToDF(RESULT, rowIdx(1)), component, scale);
        firstRow.ptr = nexOp_syncPtrFromBus(firstRow.ptr, ptrBus);
        [allTraces, ~, ~] = pgph_extractD1D2(firstRow, xKey, stackKey, ptrBus);
    end
    ySpacing = pgph_computeSpacing(allTraces, spacingMultiplier);

    % Redraw
    cla(ax);
    hold(ax, 'on');

    h_legend   = gobjects(0);
    lbl_legend = string.empty;

    if ~isResultSRC
        [traces, sems, xAxis] = pgph_extractD1D2( ...
            pgph_transformDF(nexObj.DF_postOp, component, scale), xKey, stackKey, ptrBus);
        nT = numel(traces);
        [C_traces, axLabels] = nexObj.resolveCLRColors(nexObj.DF_postOp, clrCols, nT);
        h_all = pgph_drawGroup(ax, xAxis, traces, sems, ySpacing, C_traces, alphaVal, lineWidth);
        if ~isempty(axLabels)
            h_v = h_all(isvalid(h_all));
            nL  = min(numel(h_v), numel(axLabels));
            if nL > 0, h_legend = h_v(1:nL); lbl_legend = axLabels(1:nL); end
        end
    else
        DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","cov","sem","labels"];
        allCols   = string(RESULT.Properties.VariableNames);
        grpCols   = allCols(~ismember(allCols, DF_STRUCT_FIELDS));
        nRows     = numel(rowIdx);
        rowLabels = strings(nRows, 1);
        for ri = 1:nRows
            r     = rowIdx(ri);
            parts = arrayfun(@(c) string(RESULT.(char(grpCols(c)))(r)), ...
                1:numel(grpCols), 'UniformOutput', false);
            rowLabels(ri) = strjoin([parts{:}], ' | ');
        end

        axClrCols  = clrCols(startsWith(clrCols, "ax--"));
        grpClrCols = clrCols(~startsWith(clrCols, "ax--"));
        if ~isempty(grpClrCols)
            rowBaseColors = nexObj.resolveGroupColors(RESULT(rowIdx,:), grpClrCols);
        else
            rowBaseColors = [];
        end

        axLegendDone = false;
        for gi = 1:numel(rowIdx)
            DF_g = pgph_transformDF(pgph_rowToDF(RESULT, rowIdx(gi)), component, scale);
            DF_g.ptr = nexOp_syncPtrFromBus(DF_g.ptr, ptrBus);
            [traces, sems, xAxis] = pgph_extractD1D2(DF_g, xKey, stackKey, ptrBus);
            nT = numel(traces);
            [C_traces, axLabels] = nexObj.resolveCLRColors(DF_g, axClrCols, nT);
            if ~isempty(rowBaseColors)
                baseClr = repmat(rowBaseColors(gi,:), nT, 1);
                if isempty(axClrCols)
                    C_traces = baseClr;
                else
                    C_traces = (C_traces + baseClr) / 2;
                    maxC = max(C_traces, [], 2); maxC(maxC < eps) = 1; C_traces = C_traces ./ maxC;
                end
            end
            h_all = pgph_drawGroup(ax, xAxis, traces, sems, ySpacing, C_traces, alphaVal, lineWidth);

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
        lgd.TextColor = GREEN;
        lgd.Color     = [0 0 0];
        lgd.EdgeColor = GREEN;
        lgd.FontSize  = 6;
    else
        legend(ax, 'off');
    end
end

% ── Local helpers ─────────────────────────────────────────────────────────────

function [traces, sems, xAxis] = pgph_extractD1D2(DF, xKey, stackKey, ~)
    % Caller must nexOp_syncPtrFromBus(DF.ptr, ptrBus) before calling.
    % D1/D2 use ptr.indices (or all elements); residual dims use ptr.indices
    % (multi → mean-reduce) or ptr.value (scalar lock).

    nDims  = ndims(DF.df);
    hasSEM = isfield(DF, 'sem') && isnumeric(DF.sem) ...
             && isequal(size(DF.sem), size(DF.df)) && ~isempty(DF.sem);

    hasStack = ~isempty(stackKey) && ~isequal(string(stackKey), "");

    xDim   = DF.ptr.(char(xKey)).dim;
    xIdx   = pgph_ptrIdx(DF.ptr.(char(xKey)), numel(DF.ax.(char(xKey))), true);
    xAxis  = DF.ax.(char(xKey))(xIdx);
    nT     = numel(xIdx);

    if hasStack
        stackDim = DF.ptr.(char(stackKey)).dim;
        stackIdx = pgph_ptrIdx(DF.ptr.(char(stackKey)), numel(DF.ax.(char(stackKey))), true);
        nStack   = numel(stackIdx);
    else
        stackDim = -1;
    end

    % Build full index: D1/D2 overridden above; residual from ptr.indices or ptr.value
    idx          = repmat({':'}, 1, nDims);
    idx{xDim}    = xIdx;
    if hasStack, idx{stackDim} = stackIdx; end
    residualDims = [];

    ptrFields = fieldnames(DF.ptr);
    for fi = 1:numel(ptrFields)
        f = ptrFields{fi};
        p = DF.ptr.(f);
        if ~isfield(p, 'dim') || p.dim > nDims, continue; end
        d = p.dim;
        if d == xDim || d == stackDim, continue; end
        rIdx = pgph_ptrIdx(p, numel(DF.ax.(f)), false);
        idx{d} = rIdx;
        if numel(rIdx) > 1
            residualDims(end+1) = d; %#ok<AGROW>
        end
    end
    for d = 1:nDims
        if isempty(idx{d}), idx{d} = ':'; end
    end

    % Slice + mean-reduce residual multi-index dims + squeeze
    data = DF.df(idx{:});
    if hasSEM, semData = DF.sem(idx{:}); end
    for d = sort(residualDims, 'descend')
        data = mean(data, d, 'omitnan');
        if hasSEM, semData = mean(semData, d, 'omitnan'); end
    end
    data = squeeze(data);
    if hasSEM, semData = squeeze(semData); end

    if ~hasStack
        traces = {double(data(:)')};
        if hasSEM
            sems = {double(semData(:)')};
        else
            sems = {zeros(1, nT)};
        end
        return;
    end

    traces = cell(nStack, 1);
    sems   = cell(nStack, 1);
    if xDim < stackDim
        for i = 1:nStack
            traces{i} = double(data(:, i)');
            if hasSEM
                sems{i} = double(semData(:, i)');
            else
                sems{i} = zeros(1, nT);
            end
        end
    else
        for i = 1:nStack
            traces{i} = double(data(i, :));
            if hasSEM
                sems{i} = double(semData(i, :));
            else
                sems{i} = zeros(1, nT);
            end
        end
    end
end

function sel = pgph_ptrIdx(p, nTotal, isDisplay)
% Resolve selection indices for one axis from ptr.(axis) (post-sync).
%   isDisplay = true  → fall back to 1:nTotal when no selection
%   isDisplay = false → fall back to ptr.value (scalar lock)
    if isfield(p, 'indices') && ~isempty(p.indices)
        s = sort(p.indices(p.indices >= 1 & p.indices <= nTotal));
        if ~isempty(s), sel = s; return; end
    end
    if isDisplay
        sel = 1:nTotal;
    else
        sel = p.value;
    end
end

function ySpacing = pgph_computeSpacing(traces, multiplier)
    pp = cellfun(@(t) max(double(t(:)), [], 'omitnan') - min(double(t(:)), [], 'omitnan'), traces);
    pp = pp(isfinite(pp) & pp > 0);
    if isempty(pp)
        ySpacing = 1;
    else
        ySpacing = median(pp) * multiplier;
    end
end

function h = pgph_drawGroup(ax, xAxis, traces, sems, ySpacing, C, alphaVal, lineWidth)
    % C is either 1×3 (same color for all traces) or N×3 (per-trace colors).
    h       = gobjects(0);
    nTraces = numel(traces);
    for i = 1:nTraces
        t   = double(traces{i}(:)');
        s   = double(sems{i}(:)');
        n   = min([numel(t), numel(s), numel(xAxis)]);
        if n == 0, continue; end
        x    = double(xAxis(1:n));
        t    = t(1:n);
        s    = s(1:n);
        yOff = (i - 1) * ySpacing;
        c    = C(min(i, size(C,1)), :);
        [lh, ~] = plotWithSEM(ax, x, t + yOff, s, c, alphaVal);
        if ~isempty(lh) && isvalid(lh)
            lh.LineWidth = lineWidth;
            h(end+1) = lh; %#ok<AGROW>
        end
    end
end

function DF = pgph_rowToDF(RESULT, rowIdx)
    row    = RESULT(rowIdx, :);
    DF.df  = row.df{1};
    DF.ax  = row.ax{1};
    DF.ptr = row.ptr{1};
    if ismember('sem', RESULT.Properties.VariableNames) && ~isempty(row.sem{1})
        DF.sem = row.sem{1};
    end
end

function DF = pgph_transformDF(DF_in, component, scale)
% Shallow struct copy + complex transform.  Never mutates the live DF_postOp handle.
    DF.df  = DF_in.df;
    DF.ax  = DF_in.ax;
    DF.ptr = DF_in.ptr;   % shared handle ref — intentional (ptr.indices sync propagates)
    if isfield(DF_in, 'sem') && isnumeric(DF_in.sem) && ~isempty(DF_in.sem)
        sem_in = DF_in.sem;
    else
        sem_in = [];
    end
    [DF.df, sem_out] = nexOp_applyComplexTransform(DF.df, sem_in, component, scale);
    if ~isempty(sem_out)
        DF.sem = sem_out;
    else
        DF.sem = zeros(size(DF.df));
    end
end

function rgb = pgph_toRGB(hexStr)
    hexStr = strrep(char(hexStr), '#', '');
    if numel(hexStr) == 6
        rgb = [hex2dec(hexStr(1:2)), hex2dec(hexStr(3:4)), hex2dec(hexStr(5:6))] / 255;
    else
        rgb = [0, 1, 0.25];
    end
end
