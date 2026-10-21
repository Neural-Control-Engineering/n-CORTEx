function [vals, rangeLabel, mode, dim] = nexOp_resolveSWPAxis(mdlObj, STAT, swpID)
% Resolve ONE SWP axis's candidate sweep values against STAT — a
% single-axis specialization of nexAnalysis_cvPermute.m's own per-axis
% swpAxes resolution (its section 4), for mdlObject.fitSWPGrid's
% single-select SWP (collector.View.SWP is single-select — see
% mdlObj/CLAUDE.md — unlike cvPermute's own multi-axis sweep). Same three
% branches, ported rather than re-derived: a needsHR mdlObj's reduce-mode
% FTR axis sweeps by post-reduction BLOCK label; its deferred pool-mode
% axis sweeps by post-pooling WINDOW bin-ID; anything else sweeps by raw
% per-value STAT slice.
%
%   mdlObj : the CTG-combo child (or mdlObj itself when CTG is unused) —
%            .pMap/.domain/.applyPointerDM used for narrowing
%   STAT   : this combo's own STAT (raw, pre-reduce/pool)
%   swpID  : the single SWP axis name (char/string)
%
%   vals       : candidate sweep values, already Pointer-narrowed
%   rangeLabel : one display label per val (audit trail only)
%   mode       : "ftr"  — reduce-mode FTR axis: caller narrows the
%                         already-reduced DM by COLUMN (FTR_blockColRanges)
%                "pool" — deferred pool-mode axis: caller narrows the
%                         already-pooled DM+TRAIN.G by ROW
%                         (TRAIN.G.(poolAxis)==val)
%                "raw"  — plain axis: caller re-slices raw STAT along
%                         `dim` (nexOp_sliceSTAT) and re-runs
%                         getDesignMatrix()
%   dim        : STAT's own array dimension for this axis ("raw" mode
%                only; [] otherwise)
    swpID = string(swpID);

    needsHR = false;
    if ~isempty(mdlObj.pMap)
        pmFields = fieldnames(mdlObj.pMap);
        needsHR  = any(arrayfun(@(i) mdlObj.pMap.(pmFields{i}).divsPerBin < 0, 1:numel(pmFields)));
    end
    ftrAxisStr = string(mdlObj.domain.FTR(1));
    poolAxis   = "";
    if needsHR
        poolAxis = nexOp_resolvePoolAxis(mdlObj.pMap);
    end

    ax0 = STAT.ax(1);
    raw = ax0.(char(swpID));
    dim = [];

    subjAll = string.empty;
    if ismember('subj_internal', STAT.Properties.VariableNames)
        subjAll = unique(string(STAT.subj_internal));
    end

    if needsHR && swpID == ftrAxisStr
        mode = "ftr";
        [pm_id, pmKey] = nexOp_resolvePMapEntry(mdlObj.pMap, char(swpID), ax0);
        if isempty(pm_id)
            error('nexOp_resolveSWPAxis:noPMapEntry', ...
                'SWP axis "%s" has no pMap entry, directly or via a co-indexed sibling.', swpID);
        end
        primaryVals = ax0.(pmKey);
        [~, ~, blockLabels] = pm_id.getBinEdges(primaryVals, abs(pm_id.divsPerBin), subjAll);
        vals = unique(blockLabels, 'stable');
        vals = mdlObj.applyPointerDM(swpID, vals, ax0);
        rangeLabel = vals;
    elseif needsHR && poolAxis ~= "" && swpID == poolAxis
        mode = "pool";
        pm_id = mdlObj.pMap.(char(swpID));
        [~, binIDs, binLabels] = pm_id.getBinEdges(raw, abs(pm_id.divsPerBin), subjAll);
        [uBinIDs, firstIdx] = unique(binIDs, 'stable');
        uBinLabels = binLabels(firstIdx);
        vals = uBinIDs;
        vals = mdlObj.applyPointerDM(swpID, vals, ax0);
        [~, locIdx] = ismember(vals, uBinIDs);
        rangeLabel = uBinLabels(locIdx);
    else
        mode = "raw";
        dim  = nexOp_resolveAxisDim(ax0, STAT.ptr(1), swpID);
        vals = unique(raw, 'stable');
        rangeLabel = string(vals);
    end
end
