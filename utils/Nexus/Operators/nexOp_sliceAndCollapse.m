function [df_out, ax_out] = nexOp_sliceAndCollapse(DF, displayAxes)
% Slice DF using nexOp_sliceDF then mean-reduce residual dims with multi-index
% selections, then squeeze.
%
%   DF           : struct with .df, .ax, .ptr  (ptr must be pre-synced via
%                  nexOp_syncPtrFromBus before calling)
%   displayAxes  : axis name(s) whose dims are preserved — never collapsed
%
% Selection priority per axis
%   display  : ptr.indices  >  ptr.range  >  ':'  (all)
%   residual : ptr.indices (multi → mean after)  >  ptr.value (scalar lock)
%
% Returns df_out (squeezed) and ax_out (sliced axis struct from nexOp_sliceDF).

    displayAxes = string(displayAxes);
    ptr         = DF.ptr;

    if isstruct(ptr)
        ptrFields = fieldnames(ptr);
    else
        ptrFields = properties(ptr);
    end

    axSels      = {};
    axVals      = {};
    residualDims = [];

    for fi = 1:numel(ptrFields)
        f     = ptrFields{fi};
        p     = ptr.(f);
        if ~isstruct(p) || ~isfield(p, 'dim') || isempty(p.dim), continue; end
        if ~isfield(DF.ax, f), continue; end
        raw    = DF.ax.(f);
        if isnumeric(raw) || islogical(raw)
            axArr = double(raw(:)');
        else
            axArr = raw(:)';   % string array or cellstr — keep as-is for ismember
        end
        nAx    = numel(axArr);
        isDisp = ismember(string(f), displayAxes);

        % Resolve selection for this axis
        if isfield(p, 'indices') && ~isempty(p.indices)
            sel = sort(p.indices(p.indices >= 1 & p.indices <= nAx));
        else
            sel = [];
        end

        % A display axis must keep spanning — honor its Pointer `indices` only as a
        % multi-value WINDOW (>1). A lone index would collapse it to a 1-wide slice
        % (degenerate image / invalid axis limits), which only makes sense for a
        % residual axis. So a single index on a display axis falls through to
        % range/full below instead of collapsing it.
        useSel = ~isempty(sel) && (~isDisp || numel(sel) > 1);
        if useSel
            axSels{end+1} = f;
            axVals{end+1} = axArr(sel);
            if ~isDisp && numel(sel) > 1
                residualDims(end+1) = p.dim;
            end
        elseif isDisp
            if isfield(p, 'range') && ~isempty(p.range)
                axSels{end+1} = f;
                axVals{end+1} = axArr(p.range(1):p.range(2));
            end
            % else display axis with no selection — leave as ':' (full range)
        else
            % Residual with no indices — scalar lock via ptr.value
            if isfield(p, 'value') && p.value >= 1 && p.value <= nAx
                axSels{end+1} = f;
                axVals{end+1} = axArr(p.value);
            end
        end
    end

    [raw, ax_out] = nexOp_sliceDF(DF, axSels, axVals);

    % Mean-reduce residual dims that had multi-index selections (before squeeze)
    % mean() keeps dims as size-1 so ordering doesn't matter, but descending is safe
    for d = sort(residualDims, 'descend')
        raw = mean(raw, d, 'omitnan');
    end

    df_out = squeeze(raw);
end
