function [df_out, ptr_out] = nexOp_collapseResidualDims(df_in, ptr_in, preserveAxes, ptrBus)
% Mean-reduce all ptr axes not in preserveAxes when ptrBus has multi-select (>1 indices).
% Single or empty ptrBus selections fall back to ptr.value (existing scalar-lock behaviour).
%
%   df_in        : N-D numeric array
%   ptr_in       : ptr struct or nexObj_ptr handle
%   preserveAxes : cell array or string array of axis names to leave intact
%   ptrBus       : collector.Pointer bus (has .selections struct) or []
%
% Returns:
%   df_out  : collapsed array — residual multi-selected dims reduced to size 1
%   ptr_out : plain struct copy of ptr with .value = 1 for every collapsed dim
%             (never mutates the original handle)

    df_out = df_in;

    % Plain struct copy so we never touch the nexObj_ptr handle
    if isstruct(ptr_in)
        ptr_out = ptr_in;
    else
        fns = fieldnames(ptr_in);
        ptr_out = struct;
        for i = 1:numel(fns)
            ptr_out.(fns{i}) = ptr_in.(fns{i});
        end
    end

    if isempty(ptrBus) || ~isfield(ptrBus, 'selections'), return; end

    nDims        = ndims(df_in);
    ptrFields    = fieldnames(ptr_out);
    preserveAxes = string(preserveAxes);

    collapseDims = zeros(1, 0);
    collapseIdx  = cell(1, 0);
    collapseKeys = {};

    for fi = 1:numel(ptrFields)
        f = ptrFields{fi};
        if ismember(string(f), preserveAxes), continue; end
        p = ptr_out.(f);
        if ~isfield(p, 'dim') || p.dim > nDims, continue; end
        d = p.dim;
        if ~isfield(ptrBus.selections, f), continue; end
        dimSize = size(df_in, d);
        sel = ptrBus.selections.(f);
        sel = sort(sel(sel >= 1 & sel <= dimSize));
        if numel(sel) < 2, continue; end   % single/empty → keep ptr.value lock
        collapseDims(end+1) = d;
        collapseIdx{end+1}  = sel;
        collapseKeys{end+1} = f;
    end

    if isempty(collapseDims), return; end

    % Mean-reduce in descending dim order — mean() keeps dim as size-1, no numbering shift
    [~, ord] = sort(collapseDims, 'descend');
    for k = ord
        d   = collapseDims(k);
        idx = repmat({':'}, 1, ndims(df_out));
        idx{d} = collapseIdx{k};
        df_out = mean(df_out(idx{:}), d, 'omitnan');
        ptr_out.(collapseKeys{k}).value = 1;   % only 1 element remains
    end
end
