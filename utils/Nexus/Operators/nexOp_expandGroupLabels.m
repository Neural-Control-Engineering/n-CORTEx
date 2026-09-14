function labels = nexOp_expandGroupLabels(binEdges, binLabels, nPos)
% Expand a compressed one-label-per-group list (getBinEdges' normal output
% for any divsPerBin magnitude other than 0) into one label per raw
% position. Needed wherever the underlying data is NOT actually being
% collapsed to match the compressed length — e.g. reduce-mode axes, where
% .df stays at full raw width and nexHR_fit's block-PCA only derives its
% cuts from these same boundaries later. Uses the identical discretize
% step nexObj_poolMap.pool() itself uses internally to bin data, just
% applied to labels instead.
    groupIdx = discretize(1:nPos, binEdges);
    if any(isnan(groupIdx))
        missing = find(isnan(groupIdx));
        error('nexOp_expandGroupLabels:coverageGap', ...
            'Position(s) %s not covered by any group — binEdges is incomplete.', ...
            mat2str(missing));
    end
    labels = reshape(binLabels(groupIdx), [], 1);
end
