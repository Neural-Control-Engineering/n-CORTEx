function [pm, pmKey] = nexOp_resolvePMapEntry(pMap, axisName, ax)
% Resolve axisName's pMap entry, checking its co-indexed siblings too.
%
% pMap is typically configured on whichever co-indexed sibling is
% "primary" for binning purposes — e.g. domain.REG='chans' (physical
% channel position, what region boundaries are actually defined against),
% not necessarily domain.FTR itself (e.g. 'unit', a cross-session identity
% axis that owns the real array dimension but has no meaningful position
% of its own to bin by). Mirrors the co-index resolution nexOp_poolAxes/
% resolveAxisDim already do, generalized to pMap lookup specifically.
%
%   pMap     : mdlObj.pMap
%   axisName : axis name to resolve (char/string) — e.g. domain.FTR(1)
%   ax       : a representative DF/STAT .ax struct (for nexOp_coIndexPairs)
%
%   pm    : the resolved poolMap entry, or [] if neither axisName nor any
%           co-indexed sibling has a pMap entry
%   pmKey : the field name pm was actually found under (may differ from
%           axisName) — this is what layout.axID must be set to for
%           nexHR_fit/nexHR_transform to find the right pMap entry, and
%           what layout.axVals should be read from (ax.(pmKey), not
%           ax.(axisName) — the primary axis's own values are what
%           getBinEdges' bin boundaries are actually defined against).
    axisName = char(axisName);
    if isfield(pMap, axisName)
        pm = pMap.(axisName);
        pmKey = axisName;
        return;
    end
    pm = [];
    pmKey = '';
    coIdx = nexOp_coIndexPairs(ax);
    for p = 1:numel(coIdx)
        pair = coIdx{p};
        if ~ismember(axisName, pair), continue; end
        for m = 1:numel(pair)
            cand = char(pair{m});
            if strcmp(cand, axisName), continue; end
            if isfield(pMap, cand)
                pm = pMap.(cand);
                pmKey = cand;
                return;
            end
        end
    end
end
