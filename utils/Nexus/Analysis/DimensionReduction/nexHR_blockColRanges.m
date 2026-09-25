function ranges = nexHR_blockColRanges(pm, axVals, N_ctx)
% Recompute each block's own column range within nexHR_fit's single
% concatenated (N_ctx, total_compressed_features) output, without changing
% nexHR_fit/nexHR_transform themselves (both stay general-purpose,
% single-block-loop functions with no notion of "which block is where").
%
% Mirrors nexHR_fit's own per-block width formula exactly, for the
% single-axis-layout case (empty inner_layout — its base case is a pure
% flatten, so n_feat == curBlockSize):
%   nComp_actual = min(pm.reducerDim, min([N_ctx, curBlockSize]))
%
%   pm     : the FTR axis's poolMap entry (mdlObj.pMap.(ftrAxis))
%   axVals : that axis's raw tick values (layout.axVals from fitReduce)
%   N_ctx  : sample count nexHR_fit was actually called with
%            (size(X_raw, 1)) — block widths depend on it via the same
%            min([N_ctx, curBlockSize]) clamp nexHR_fit applies
%
%   ranges : struct array, one per block, in nexHR_fit's own block order
%            (matching binEdges' order — the concatenation order of its
%            block_outs): .label (this block's bin label, e.g. region
%            name) and .cols (column indices into the reduced X)

    [binEdges, ~, binLabels] = pm.getBinEdges(axVals, abs(pm.divsPerBin));
    nBlocks  = numel(binEdges) - 1;
    ranges   = struct('label', {}, 'cols', {});
    colStart = 1;
    for b = 1:nBlocks
        curBlockSize = binEdges(b+1) - binEdges(b);
        nComp_actual = min(pm.reducerDim, min([N_ctx, curBlockSize]));
        ranges(b).label = binLabels(b);
        ranges(b).cols  = colStart:(colStart + nComp_actual - 1);
        colStart = colStart + nComp_actual;
    end
end
