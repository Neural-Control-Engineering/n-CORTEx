function mask = nexOp_matchesSWPValue(vals, target)
% Match raw SWP labels against one unique value (cell/string/numeric) —
% the "raw" (non-needsHR) SWP narrowing primitive's own value-match step.
% Extracted from nexAnalysis_cvPermute.m's own local matchesSWPValue (DRY
% — shared by fitSWPGrid and cvPermute's own multi-axis sweep; behavior
% unchanged, just no longer duplicated).
    if iscell(target), target = target{1}; end
    if iscell(vals)
        mask = strcmp(vals, target);
    else
        mask = vals == target;
    end
end
