function [X_pooled, G_pooled] = nexOp_poolStackedDM(X, G, pMap, poolAxis)
% Post-reduction time pooling: group stacked rows by (trialIdx,
% window-bin-of G.(poolAxis)) and mean-pool X within each group. This is
% what replaces nexOp_poolAxes's pool-mode collapsing for a needsHR
% mdlObj — deferred until after reduction so reduction (fitReduce/
% applyReduce) sees full raw-timepoint resolution instead of an
% already-averaged, decimated version of it (see WIP.md #3).
%
% Windowing is position-based per trial (nexOp_getBinEdges's own
% convention — groups every divsPerBin consecutive ROW positions within
% that trial), matching exactly how nexOp_poolAxes's existing pool-mode
% branch pools each trial's raw timepoints independently.
%
%   X        : (nRows, nFeatures) — e.g. fitReduce/applyReduce's output
%   G        : companion table, nRows tall, with a trialIdx column and
%              a poolAxis column (nexOp_stackByFTR's own output shape)
%   pMap     : full pMap (poolAxis's own entry drives bin edges)
%   poolAxis : axis name to pool over (char/string), e.g. "t"
%
%   X_pooled : (nGroups, nFeatures) — mean-pooled (omitnan)
%   G_pooled : one row per group — poolAxis column replaced with each
%              window's bin-start representative value (matching real
%              pool-mode pooling's own DF_pooled.ax.(axSel)=binIDs
%              convention — see nexObj_poolMap.pool()); every other
%              column takes the group's (constant within-trial) value.

    poolAxis = char(poolAxis);
    pm = pMap.(poolAxis);

    trialIDs = G.trialIdx;
    uTrials  = unique(trialIDs, 'stable');

    X_out_cell = cell(numel(uTrials), 1);
    G_out_cell = cell(numel(uTrials), 1);

    for ti = 1:numel(uTrials)
        rowsT  = find(trialIDs == uTrials(ti));
        axVals = G.(poolAxis)(rowsT);
        [binEdges, binIDs] = pm.getBinEdges(axVals, abs(pm.divsPerBin));
        nBins  = numel(binEdges) - 1;
        bins   = discretize(1:numel(rowsT), binEdges);

        Xt = X(rowsT, :);
        Gt = G(rowsT, :);

        Xg       = nan(nBins, size(X, 2));
        Gg       = Gt(1:nBins, :);   % placeholder rows — every row overwritten below
        keepMask = false(nBins, 1);
        for b = 1:nBins
            m = bins == b;
            if ~any(m), continue; end
            Xg(b, :)       = mean(Xt(m, :), 1, 'omitnan');
            Gg(b, :)       = Gt(find(m, 1), :);
            Gg.(poolAxis)(b) = binIDs(b);
            keepMask(b)    = true;
        end
        X_out_cell{ti} = Xg(keepMask, :);
        G_out_cell{ti} = Gg(keepMask, :);
    end

    X_pooled = cat(1, X_out_cell{:});
    G_pooled = cat(1, G_out_cell{:});
    fprintf('[nexOp_poolStackedDM] %s -> %s (poolAxis=%s, %d trial(s))\n', ...
            mat2str(size(X)), mat2str(size(X_pooled)), poolAxis, numel(uTrials));
end
