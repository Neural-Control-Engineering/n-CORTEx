function nexVisualization_waterfall(nexObj, args)

    % CFG HEADER
    alphaVal = args.alphaVal; % default = 0.15
    lineWidth = args.lineWidth; % default = 1.5
    spacingMultiplier = args.spacingMultiplier; % default = 1.0

    % Guard
    DFp = nexObj.DF_postOp;
    if isempty(DFp) ...
            || (~isstruct(DFp) && ~isa(DFp, 'nexObj_DF')) ...
            || isempty(DFp.df)
        return;
    end

    ax = nexObj.Figure.panel0.tiles.ax;
    C  = nexObj.nexon.settings.Colors;

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

    ptrBus = nexObj.collector.Pointer;

    % Compute shared y-spacing from first / only DF
    if ~isResultSRC
        [allTraces, ~, ~] = wtfl_extractD1D2(nexObj.DF_postOp, xKey, stackKey, ptrBus);
    else
        RESULT   = nexObj.RESULTS.(srcKey);
        viewSel  = nex_returnSelectionMask(nexObj.collector.View);
        rowIdx   = nexObj.filterResultsByVW(RESULT, viewSel.VW);
        firstRow = wtfl_rowToDF(RESULT, rowIdx(1));
        [allTraces, ~, ~] = wtfl_extractD1D2(firstRow, xKey, stackKey, ptrBus);
    end
    ySpacing = wtfl_computeSpacing(allTraces, spacingMultiplier);

    % Redraw
    cla(ax);
    hold(ax, 'on');

    if ~isResultSRC
        GREEN = C.cyberGreen;
        if ischar(GREEN) || isstring(GREEN)
            GREEN = wtfl_toRGB(GREEN);
        end
        [traces, sems, xAxis] = wtfl_extractD1D2(nexObj.DF_postOp, xKey, stackKey, ptrBus);
        wtfl_drawGroup(ax, xAxis, traces, sems, ySpacing, GREEN, alphaVal, lineWidth);
        legend(ax, 'off');
    else
        clrCols = string(viewSel.CLR);
        clrCols = clrCols(clrCols ~= "");
        C_grp   = nexObj.resolveGroupColors(RESULT(rowIdx, :), clrCols);

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

        h_legend   = gobjects(0);
        lbl_legend = string.empty;
        for gi = 1:numel(rowIdx)
            DF_g = wtfl_rowToDF(RESULT, rowIdx(gi));
            [traces, sems, xAxis] = wtfl_extractD1D2(DF_g, xKey, stackKey, ptrBus);
            h = wtfl_drawGroup(ax, xAxis, traces, sems, ySpacing, C_grp(gi,:), alphaVal, lineWidth);
            if ~isempty(h) && isvalid(h)
                h_legend(end+1)   = h;             %#ok<AGROW>
                lbl_legend(end+1) = rowLabels(gi); %#ok<AGROW>
            end
        end

        if ~isempty(h_legend)
            GREEN_rgb = C.cyberGreen;
            if ischar(GREEN_rgb) || isstring(GREEN_rgb)
                GREEN_rgb = wtfl_toRGB(GREEN_rgb);
            end
            lgd = legend(ax, h_legend, cellstr(lbl_legend), 'Interpreter', 'none');
            lgd.TextColor = GREEN_rgb;
            lgd.Color     = [0 0 0];
            lgd.EdgeColor = GREEN_rgb;
            lgd.FontSize  = 16;
        end
    end

    hold(ax, 'off');
    colorAx_green(ax);
    xlabel(ax, char(xKey), 'Color', C.cyberGreen);
    if ~isequal(stackKey, "")
        ylabel(ax, char(stackKey), 'Color', C.cyberGreen);
    end
    zlabel(ax, 'magnitude', 'Color', C.cyberGreen);
    % view(ax, -30, 30);
end

% ── Local helpers ─────────────────────────────────────────────────────────────

function [traces, sems, xAxis] = wtfl_extractD1D2(DF, xKey, stackKey, ptrBus)
    % Slices DF.df using Pointer bus selections for both D1 (x-axis) and D2
    % (stacking axis) simultaneously, then splits the 2D result into per-stack
    % traces. All other dims are locked to ptr.value.
    %
    % idx is built once:
    %   idx{xDim}    = xIdx    — array of selected x positions
    %   idx{stackDim} = stackIdx — array of selected stack positions
    %   idx{other}   = ptr.value — scalar lock
    %
    % One slice: data = squeeze(DF.df(idx{:})) → 2D matrix
    % Orientation after squeeze is determined by relative dim order:
    %   xDim < stackDim  →  rows = x,     cols = stack
    %   xDim > stackDim  →  rows = stack, cols = x
    % Each stack position becomes one trace in the output cell array.

    nDims  = ndims(DF.df);
    hasSEM = isfield(DF, 'sem') && isnumeric(DF.sem) ...
             && isequal(size(DF.sem), size(DF.df)) && ~isempty(DF.sem);

    % Base index: lock all dims to ptr.value
    idx = cell(1, nDims);
    ptrFields = fieldnames(DF.ptr);
    for fi = 1:numel(ptrFields)
        f = ptrFields{fi};
        p = DF.ptr.(f);
        if isfield(p, 'dim') && p.dim <= nDims
            idx{p.dim} = p.value;
        end
    end
    for d = 1:nDims
        if isempty(idx{d}), idx{d} = ':'; end
    end

    % D1: override xDim with Pointer bus selection
    xDim = DF.ptr.(char(xKey)).dim;
    xIdx = wtfl_ptrSelIdx(ptrBus, char(xKey), numel(DF.ax.(char(xKey))));
    idx{xDim} = xIdx;
    xAxis = DF.ax.(char(xKey))(xIdx);
    nT    = numel(xIdx);

    hasStack = ~isempty(stackKey) && ~isequal(string(stackKey), "");

    if ~hasStack
        data = squeeze(DF.df(idx{:}));
        traces = {double(data(:)')};
        if hasSEM
            try
                % sems = {double(squeeze(DF.sem(idx{:}))(:)')};
                sems = {double(squeeze(DF.sem(idx{:}))')};
            catch
                keyboard
            end
        else
            sems = {zeros(1, nT)};
        end
        return;
    end

    % D2: override stackDim with Pointer bus selection
    stackDim = DF.ptr.(char(stackKey)).dim;
    stackIdx = wtfl_ptrSelIdx(ptrBus, char(stackKey), numel(DF.ax.(char(stackKey))));
    idx{stackDim} = stackIdx;
    nStack = numel(stackIdx);

    % Single 2D slice
    data = squeeze(DF.df(idx{:}));
    if hasSEM
        semData = squeeze(DF.sem(idx{:}));
    end

    % Split along the stack dimension of the squeezed result.
    % squeeze preserves dim order, so the axis with the lower original dim
    % number becomes dim 1 of the result.
    traces = cell(nStack, 1);
    sems   = cell(nStack, 1);
    if xDim < stackDim
        % data: nT rows × nStack cols
        for i = 1:nStack
            traces{i} = double(data(:, i)');
            if hasSEM
                sems{i} = double(semData(:, i)');
            else
                sems{i} = zeros(1, nT);
            end
        end
    else
        % data: nStack rows × nT cols
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

function sel = wtfl_ptrSelIdx(ptrBus, key, nTotal)
    % Returns Pointer bus selection indices for 'key', or 1:nTotal if unset.
    if ~isempty(ptrBus) && isfield(ptrBus.selections, key)
        s = ptrBus.selections.(key);
        s = sort(s(s >= 1 & s <= nTotal));
        if ~isempty(s), sel = s; return; end
    end
    sel = 1:nTotal;
end

function ySpacing = wtfl_computeSpacing(traces, multiplier)
    pp = cellfun(@(t) max(double(t(:)),[],'omitnan') - min(double(t(:)),[],'omitnan'), traces);
    pp = pp(isfinite(pp) & pp > 0);
    ySpacing = 1;
    if ~isempty(pp)
        ySpacing = median(pp) * multiplier;
    end
end

function h = wtfl_drawGroup(ax, xAxis, traces, sems, ySpacing, color, alphaVal, lineWidth)
    h       = gobjects(0);
    nTraces = numel(traces);
    x       = double(xAxis(:)');
    for i = 1:nTraces
        z   = double(traces{i}(:)');
        s   = double(sems{i}(:)');
        n   = min([numel(x), numel(z), numel(s)]);
        if n == 0, continue; end
        x_i = x(1:n);  z_i = z(1:n);  s_i = s(1:n);
        y_i = (i - 1) * ySpacing;

        % Main 3D trace
        lh = plot3(ax, x_i, y_i * ones(1,n), z_i, '-', ...
            'Color',     color, ...
            'LineWidth', lineWidth);
        if isempty(h), h = lh; end

        % SEM ribbon — transparent surf spanning [z-sem, z+sem] at constant Y
        if any(s_i > 0)
            x2 = [x_i; x_i];
            y2 = y_i * ones(2, n);
            z2 = [z_i + s_i; z_i - s_i];
            surf(ax, x2, y2, z2, ...
                'FaceColor', color, ...
                'FaceAlpha', alphaVal, ...
                'EdgeColor', 'none');
        end
    end
end


function DF = wtfl_rowToDF(RESULT, rowIdx)
    row  = RESULT(rowIdx, :);
    DF.df  = row.df{1};
    DF.ax  = row.ax{1};
    DF.ptr = row.ptr{1};
    if ismember('sem', RESULT.Properties.VariableNames) && ~isempty(row.sem{1})
        DF.sem = row.sem{1};
    end
end

function rgb = wtfl_toRGB(hexStr)
    hexStr = strrep(char(hexStr), '#', '');
    if numel(hexStr) == 6
        rgb = [hex2dec(hexStr(1:2)), hex2dec(hexStr(3:4)), hex2dec(hexStr(5:6))] / 255;
    else
        rgb = [0, 1, 0.25];
    end
end
