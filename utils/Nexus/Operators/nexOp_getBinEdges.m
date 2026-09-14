function [binEdges, binIDs, binLabels] = nexOp_getBinEdges(axis, divsPerBin)
% Position-based binning robust to non-contiguous axis values.
% Groups every divsPerBin elements by position, then labels each bin
% using the actual axis values at the start and end of that position range.
    if divsPerBin == 0 || isempty(axis)
        binEdges = []; binIDs = []; binLabels = string([]); return;
    end
    % Force column orientation up front. MATLAB's linear-indexing-of-a-vector
    % rule returns a result matching the SOURCE vector's own orientation, not
    % the index's — so axis(binStart) silently comes back as a row if axis is
    % a row vector, even though binStart is a column. That orientation
    % mismatch between the two compose() arguments is what was throwing
    % "Format must have enough conversion operators". Normalizing axis (and
    % the two index results, defensively) to columns removes the ambiguity.
    axis     = axis(:);
    N        = numel(axis);
    binStart = (1 : divsPerBin : N)';
    binEnd   = min(binStart + divsPerBin - 1, N);
    binEdges = [binStart; N + 1];
    binIDs   = axis(binStart);
    startVals = axis(binStart); startVals = startVals(:);
    endVals   = axis(binEnd);   endVals   = endVals(:);
    binLabels = compose("%d--%d", startVals, endVals);
end
