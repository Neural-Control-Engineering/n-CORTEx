function [X_pooled, G_pooled] = nexOp_poolStackedDM(X, G, pMap, poolAxes)
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
% poolAxes may name MORE THAN ONE simultaneously pool-mode axis (WIP.md
% #19 follow-up — nexOp_resolvePoolAxis can now return several). These
% are pooled HIERARCHICALLY, not independently: poolAxes(1) bins
% positionally over every row in the trial (exactly the original,
% single-axis algorithm — byte-for-byte, when only one axis is given);
% poolAxes(2) then bins positionally WITHIN each of poolAxes(1)'s own
% surviving row-groups; and so on. This is a real, order-dependent choice
% (poolAxes(1) is "outer", poolAxes(end) is "innermost") — there is no
% axis-order-independent way to jointly position-bin two axes whose rows
% are interleaved (nexOp_stackByFTR's own nested expansion), so nesting
% order is explicit rather than implicit. Mirrors nexHR_fit's own
% recursive block structure, for pooling instead of reduction.
%
%   X        : (nRows, nFeatures) — e.g. fitReduce/applyReduce's output
%   G        : companion table, nRows tall, with a trialIdx column and
%              one column per axis named in poolAxes (nexOp_stackByFTR's
%              own output shape)
%   pMap     : full pMap (each poolAxes entry's own entry drives its bin edges)
%   poolAxes : axis name(s) to pool over (string array, outer-to-inner
%              order), e.g. "t", or ["chans","t"]
%
%   X_pooled : (nGroups, nFeatures) — mean-pooled (omitnan)
%   G_pooled : one row per group — each pooled axis's own column replaced
%              with its window's bin-start representative value (matching
%              real pool-mode pooling's own DF_pooled.ax.(axSel)=binIDs
%              convention — see nexObj_poolMap.pool()); every other
%              column takes the group's (constant within-group) value.

    poolAxes = string(poolAxes);
    trialIDs = G.trialIdx;
    uTrials  = unique(trialIDs, 'stable');

    X_out_cell = cell(numel(uTrials), 1);
    G_out_cell = cell(numel(uTrials), 1);

    for ti = 1:numel(uTrials)
        rowsT = find(trialIDs == uTrials(ti));
        [X_out_cell{ti}, G_out_cell{ti}] = nexOp_poolStackedDM_recurse( ...
            X(rowsT, :), G(rowsT, :), pMap, poolAxes);
    end

    X_pooled = cat(1, X_out_cell{:});
    G_pooled = cat(1, G_out_cell{:});
    fprintf('[nexOp_poolStackedDM] %s -> %s (poolAxes=%s, %d trial(s))\n', ...
            mat2str(size(X)), mat2str(size(X_pooled)), strjoin(poolAxes, ","), numel(uTrials));
end

function [Xg_all, Gg_all] = nexOp_poolStackedDM_recurse(Xt, Gt, pMap, poolAxes)
% One axis's worth of positional binning, applied to whatever row subset
% the caller already narrowed to (the whole trial, for the outermost
% axis; one bin's own surviving rows, for every axis after that).
    axisName = char(poolAxes(1));
    pm       = pMap.(axisName);
    axVals   = Gt.(axisName);
    [binEdges, binIDs, binLabels] = pm.getBinEdges(axVals, abs(pm.divsPerBin));
    nBins  = numel(binEdges) - 1;
    bins   = discretize(1:height(Gt), binEdges);
    % divsPerBin==0 (mapID-type axis, e.g. epoch): one bin PER RAW
    % POSITION, so binIDs is unique per position -- useless for grouping
    % (defeats the whole point: every row would be its own "group" again).
    % binLabels is the actual shared group name (e.g. "during", repeated
    % across every row in that group) -- that's the one that makes
    % "pooling" degenerate to "relabeling" correctly. For divsPerBin>0,
    % unchanged: binIDs is the real per-window identity, same as before.
    if pm.divsPerBin == 0
        binRepVal = binLabels;
    else
        binRepVal = binIDs;
    end

    if isscalar(poolAxes)
        % Base case — identical to the original single-axis algorithm
        % (divsPerBin>0 path unchanged; binRepVal==binIDs there).
        Xg       = nan(nBins, size(Xt, 2));
        Gg       = Gt(1:nBins, :);   % placeholder rows — every row overwritten below
        keepMask = false(nBins, 1);
        Gg.(axisName) = nexOp_poolStackedDM_retype(Gg.(axisName), binRepVal);
        for b = 1:nBins
            m = bins == b;
            if ~any(m), continue; end
            Xg(b, :)         = mean(Xt(m, :), 1, 'omitnan');
            Gg(b, :)         = Gt(find(m, 1), :);
            Gg.(axisName)(b) = binRepVal(b);
            keepMask(b)      = true;
        end
        Xg_all = Xg(keepMask, :);
        Gg_all = Gg(keepMask, :);
        return;
    end

    % Recursive case — bin THIS axis, then within each surviving bin's
    % own rows, recurse into the remaining (inner) axes.
    Xg_cell = cell(nBins, 1);
    Gg_cell = cell(nBins, 1);
    for b = 1:nBins
        m = bins == b;
        if ~any(m), continue; end
        [Xg_b, Gg_b] = nexOp_poolStackedDM_recurse(Xt(m, :), Gt(m, :), pMap, poolAxes(2:end));
        Gg_b.(axisName) = nexOp_poolStackedDM_retype(Gg_b.(axisName), binRepVal);
        Gg_b.(axisName)(:) = binRepVal(b);   % this axis's own bin-id (or group
                                              % label, if divsPerBin==0), constant
                                              % across every inner-axis group it produced
        Xg_cell{b} = Xg_b;
        Gg_cell{b} = Gg_b;
    end
    Xg_all = cat(1, Xg_cell{:});
    Gg_all = cat(1, Gg_cell{:});
end

function col = nexOp_poolStackedDM_retype(col, repVal)
% Retype a G column to match whatever's actually about to be written into
% it, generically -- not gated on divsPerBin, so it stays correct for any
% future case where the per-bin representative value's class doesn't
% match the column's existing one (today: binLabels is string while the
% column was built from a raw numeric axis -- Nexus WIP.md #19). A plain
% element assignment into a column typed differently from the value being
% assigned doesn't retype the column; it silently coerces (and fails to
% <missing> for an unconvertible case like string->double) -- so the
% WHOLE column is retyped up front whenever there's a real mismatch.
% str2func + an explicit handle call, not feval -- same "class name as
% its own standard conversion function" idea, without feval's lookup/
% dispatch behavior. No-op (returns col unchanged) when the types already
% match -- e.g. every existing divsPerBin>0 caller, where binRepVal is
% numeric binIDs, same as the column already is.
    if ~strcmp(class(col), class(repVal))
        convFcn = str2func(class(repVal));
        col = convFcn(col);
    end
end
