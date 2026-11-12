function poolAxis = nexOp_resolvePoolAxis(pMap)
% Find every pool-mode axis in a pMap — the axis(es) nexOp_poolStackedDM
% pools AFTER reduction for a needsHR mdlObj, instead of nexOp_poolAxes
% pooling it at compile time (see WIP.md #3). Shared by
% nexAnalysis_cvPermute's per-fold/SWP reduce-then-pool sequence and
% mdlObject's own (getDesignMatrix/flattenInput, for a plain fit()).
%
% Qualifies as "pool-mode": divsPerBin > 0 (ordinary collapse), OR
% divsPerBin == 0 on a mapID-type axis (e.g. epoch's before/during/after,
% region, band) — same binType==mapID vs axID distinction
% nexOp_poolAxes.m's own per-axis skip already uses. divsPerBin==0 doesn't
% collapse anything (getBinEdges returns one edge per raw position), so
% nexOp_poolStackedDM's mean-pool of each single-row "bin" is just that
% row unchanged — pooling degenerates to relabeling at that grain, through
% the SAME mechanism, rather than needing a separate relabel-only code
% path (Nexus WIP.md #19 follow-up). divsPerBin==0 on a plain axID axis is
% a genuinely different thing ("no-op, don't touch this axis at all" —
% getBinEdges deliberately returns empty edges for that case) and must
% NOT be included here, or nexOp_poolStackedDM would hand discretize an
% empty edge list and crash.
%
% Returns EVERY matching field, not just the first — a pMap can
% legitimately have more than one simultaneously pool-mode axis (e.g. t
% epoch-pooled AND f band-pooled on the same needsHR mdlObj). Kept this
% function's name singular ("Axis") since every existing call site already
% reads its result into a variable named poolAxis and just forwards it to
% nexOp_poolStackedDM unchanged — that function now accepts either a
% scalar or an array (WIP.md #19 follow-up) — so no call site needed
% updating for this change; only nexOp_poolStackedDM's own internals did.
%
%   pMap     : mdlObj.pMap
%   poolAxis : string array of axis names, in pMap field order: empty
%              (string.empty) if none, scalar if exactly one — existing
%              callers' own `poolAxis ~= ""` idiom still works correctly
%              either way (empty is falsy in `if`; a 1xN array of
%              nonempty strings is still all-true).
    poolAxis = string.empty;
    if isempty(pMap), return; end
    fields = fieldnames(pMap);
    for i = 1:numel(fields)
        pm = pMap.(fields{i});
        isMapIDZero = pm.divsPerBin == 0 && string(pm.binType) == string(pm.mapID);
        if pm.divsPerBin > 0 || isMapIDZero
            poolAxis(end+1) = string(fields{i}); %#ok<AGROW>
        end
    end
end
