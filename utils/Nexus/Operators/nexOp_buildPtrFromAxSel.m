function ptr = nexOp_buildPtrFromAxSel(S_categories, S_items, nexObj)
% Build a ptr plain struct from ax-- category selections.
%
%   ptr = nexOp_buildPtrFromAxSel(S_categories, S_items, nexObj)
%
%   For each ax-- slot in S_categories with a non-None item selection, the
%   selected values are looked up in nexObj.DF_postOp.ax.(axName) and the
%   resulting indices are collapsed to [min, max] — covering the full span
%   of the selection. Returns [] when no ax-- selections are active.
%
%   Called by nexOp_compileSTAT and nexObject.reportAverage_batched to
%   enable hyperslab reads on chunked HDF5 datasets.

    ptr = struct;
    catFields = fieldnames(S_categories);
    for i = 1:numel(catFields)
        catKey = catFields{i};
        catVal = string(S_categories.(catKey));
        if ~startsWith(catVal, "ax--"), continue; end
        axName  = char(extractAfter(catVal, "ax--"));
        selVals = S_items.(catKey);
        if isempty(selVals) || (isscalar(selVals) && strcmp(string(selVals), "None"))
            continue;
        end
        try
            axArr = nexObj.DF_postOp.ax.(axName);
        catch
            continue;
        end
        if isempty(axArr), continue; end

        if isnumeric(axArr)
            numVals = double(string(selVals));
            numVals = numVals(~isnan(numVals));
            if isempty(numVals), continue; end
            indices = arrayfun(@(v) nearestIdx(axArr, v), numVals);
        else
            indices = find(ismember(string(axArr), string(selVals)));
        end
        if isempty(indices), continue; end
        ptr.(axName).range = [min(indices), max(indices)];
    end
    if isempty(fieldnames(ptr)), ptr = []; end
end

function idx = nearestIdx(arr, val)
    [~, idx] = min(abs(arr(:) - val));
end
