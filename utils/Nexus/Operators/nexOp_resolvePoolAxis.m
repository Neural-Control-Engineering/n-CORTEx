function poolAxis = nexOp_resolvePoolAxis(pMap)
% Find the pool-mode axis (divsPerBin > 0) in a pMap, if any — the axis
% nexOp_poolStackedDM pools AFTER reduction for a needsHR mdlObj, instead
% of nexOp_poolAxes pooling it at compile time (see WIP.md #3). Shared by
% nexAnalysis_cvPermute's per-fold/SWP reduce-then-pool sequence and
% mdlObject's own (getDesignMatrix/flattenInput, for a plain fit()).
%
%   pMap     : mdlObj.pMap
%   poolAxis : axis name (string), or "" if none / pMap is empty
    poolAxis = "";
    if isempty(pMap), return; end
    fields = fieldnames(pMap);
    for i = 1:numel(fields)
        if pMap.(fields{i}).divsPerBin > 0
            poolAxis = string(fields{i});
            return;
        end
    end
end
