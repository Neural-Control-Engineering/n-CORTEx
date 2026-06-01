function [traces, sems, xAxis] = nexVis_extractD1D2(DF, xKey, stackKey, ~)
% Extract D1/D2 axis slices from a DF struct as cell arrays of row vectors.
%
% Caller must nexOp_syncPtrFromBus(DF.ptr, ptrBus) before calling.
% D1/D2 use ptr.indices (or all elements); residual dims use ptr.indices
% (multi → mean-reduce) or ptr.value (scalar lock).

    nDims  = ndims(DF.df);
    hasSEM = isfield(DF, 'sem') && isnumeric(DF.sem) ...
             && isequal(size(DF.sem), size(DF.df)) && ~isempty(DF.sem);

    hasStack = ~isempty(stackKey) && ~isequal(string(stackKey), "");

    xDim   = DF.ptr.(char(xKey)).dim;
    xIdx   = nexVis_ptrIdx(DF.ptr.(char(xKey)), numel(DF.ax.(char(xKey))), true);
    xAxis  = DF.ax.(char(xKey))(xIdx);
    nT     = numel(xIdx);

    if hasStack
        stackDim = DF.ptr.(char(stackKey)).dim;
        stackIdx = nexVis_ptrIdx(DF.ptr.(char(stackKey)), numel(DF.ax.(char(stackKey))), true);
        nStack   = numel(stackIdx);
    else
        stackDim = -1;
    end

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
        rIdx = nexVis_ptrIdx(p, numel(DF.ax.(f)), false);
        idx{d} = rIdx;
        if numel(rIdx) > 1
            residualDims(end+1) = d; %#ok<AGROW>
        end
    end
    for d = 1:nDims
        if isempty(idx{d}), idx{d} = ':'; end
    end

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
        sems   = {double(hasSEM * semData(:)')};
        if ~hasSEM, sems = {zeros(1, nT)}; end
        return;
    end

    traces = cell(nStack, 1);
    sems   = cell(nStack, 1);
    if xDim < stackDim
        for i = 1:nStack
            traces{i} = double(data(:, i)');
            sems{i}   = hasSEM * double(semData(:, i)');
            if ~hasSEM, sems{i} = zeros(1, nT); end
        end
    else
        for i = 1:nStack
            traces{i} = double(data(i, :));
            sems{i}   = hasSEM * double(semData(i, :));
            if ~hasSEM, sems{i} = zeros(1, nT); end
        end
    end
end

% ── Local helper ──────────────────────────────────────────────────────────────

function sel = nexVis_ptrIdx(p, nTotal, isDisplay)
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
