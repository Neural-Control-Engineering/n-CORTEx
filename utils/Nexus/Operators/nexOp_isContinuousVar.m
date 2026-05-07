function tf = nexOp_isContinuousVar(vals)
% True when vals should be quantile-binned (continuous); false when the column
% represents deliberately enumerated integer categories (1, 2, 3, ...) that
% should pass through unchanged regardless of nBins.
%
% Rule: if every unique non-NaN value has zero fractional part the column is
% treated as enumerated and binning is skipped.
    if ~isnumeric(vals), tf = false; return; end
    uniq = unique(vals(~isnan(vals(:))));
    tf   = ~all(mod(uniq, 1) == 0);
end
