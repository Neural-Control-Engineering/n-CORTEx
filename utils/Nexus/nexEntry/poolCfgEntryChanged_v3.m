function poolCfgEntryChanged_v3(src, ~, poolMap, field, nexObj)
    poolMap.(field) = src.Value;
    if nargin < 5 || isempty(nexObj), return; end
    % Lazy ax-only update: recompute axis labels from pMap without pooling
    % DF.df. Source from nexObj.DF (frozen at construction, never overwritten
    % by pooling) so repeated spinner changes don't accumulate drift.
    % Writing DF_postOp.ax triggers PostSet → refreshPointer.
    try
        postOp = resolvePostOp(nexObj);
        if isempty(postOp), return; end
        pMap = resolvePMap(nexObj);
        if isempty(pMap), return; end
        rawDF = resolveRawDF(nexObj);
        if isempty(rawDF) || ~isfield(rawDF, 'ax'), return; end
        postOp.ax = nexOp_poolAx(pMap, rawDF);
        if ismethod(nexObj, 'refreshPointer')
            nexObj.refreshPointer();
        end
    catch e
        fprintf('[poolCfgEntryChanged_v3] lazy ax update failed: %s\n', e.message);
    end
end


function postOp = resolvePostOp(nexObj)
    try
        postOp = nexObj.DF_postOp;
    catch
        try
            postOp = nexObj.Origin.DF_postOp;
        catch
            postOp = [];
        end
    end
end


function pMap = resolvePMap(nexObj)
    try
        pMap = nexObj.pMap;
    catch
        try
            pMap = nexObj.Origin.pMap;
        catch
            pMap = [];
        end
    end
end


function rawDF = resolveRawDF(nexObj)
    try
        rawDF = nexObj.DF;
    catch
        try
            rawDF = nexObj.Origin.DF;
        catch
            rawDF = [];
        end
    end
end
