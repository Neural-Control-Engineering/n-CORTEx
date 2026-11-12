function [X3D, trialOrder, binLabels] = nexOp_reshapeStackedByTrial(X, G, poolAxis)
% Reconstitute a flat (nGroups, nFeatures) reduced+pooled matrix
% (nexOp_poolStackedDM's own output shape) back into a real
% (nTrials, nBins, nFeatures) array.
%
% nexOp_poolStackedDM is deliberately trial-blind — the right contract
% for PCA/LDA, which want i.i.d. samples, no notion of "sequence" — so
% trial identity survives only as G's own trialIdx/poolAxis-bin columns,
% not as an array dimension. A sequence model (SSM/dynamax) needs that
% structure back as a real dimension: dynamax's batched EM/filter treat a
% 3D (num_trials, T, emission_dim) input as INDEPENDENT per-trial
% sequences (confirmed directly in dynamax's own ssm.py — fit_em vmaps
% the E-step across the batch dim; pytafix's own filter() vmaps the same
% way for ndim==3), not one sequence concatenated end-to-end — which is
% exactly what the flat (nGroups, nFeatures) shape would look like if fed
% in as-is for more than one trial.
%
% Rows for each trial are assumed already contiguous and in ascending
% bin order — true by construction for nexOp_poolStackedDM's own output
% (it loops trial-by-trial, appending consecutive bins in order, then
% concatenates trial blocks in trial order).
%
% TRIALS CAN COME UP SHORT A BIN OR TWO, AND THAT'S HANDLED BY PADDING,
% NOT ERRORING (Nexus WIP.md #17/#19/#21): under divsPerBin==0 (e.g.
% epoch labeling), bin count is raw-resolution and genuinely trial-
% dependent (map_epochs2time resolves each trial's own epoch boundaries
% against that trial's own real timestamps, which can differ by a sample
% or two even when trial lengths were already trimmed to a common raw
% count). Short trials are zero-padded (at the END of their own real
% rows, never touching any OTHER trial's data) up to the longest trial's
% bin count, rather than trimming every trial down to the shortest:
% trimming would throw away REAL data from every trial just to
% accommodate whichever ones happened to be short, and would risk
% shifting what "index k" means for the trimmed trials relative to the
% ones left alone. Padding only ever touches the few short trials, and
% only ever appends after their real data, so no trial's real
% correspondence is altered.
%
% ZERO, not NaN: confirmed directly against the installed dynamax source
% (lgssm_filter's own _step, linear_gaussian_ssm/inference.py) that there
% is no missing-observation masking anywhere in the Kalman filter/EM
% path -- emissions(t) feeds the log-likelihood and the Kalman update
% completely unconditionally, every step, with no NaN check. Since this
% is a lax.scan-style recursion where (pred_mean, pred_cov) carries
% forward from each step to the next, a single NaN wouldn't just mark
% one bad timestep -- it would propagate through the ENTIRE REST of that
% trial's filtered sequence, corrupting fit_em's log-likelihood for the
% whole batch. Zero is safe because X is already mean-centered (Scaler,
% fit inside fitReduce before this ever runs) -- a zero reads as "the
% dataset's own average observation," not an arbitrary value, at the
% small number of padded positions.
%
%   X        : (nGroups, nFeatures) — e.g. mdlObj.DM (needsHR "stack" format)
%   G        : companion table, nGroups tall, with a .trialIdx column
%              (mdlObj.TRAIN.G's own shape)
%   poolAxis : pool axis name (char/string), or "" if this needsHR mdlObj
%              has no designated pool-mode axis (reduce-only — getDesignMatrix
%              then sets G to fitReduce's own raw-stacked G, un-pooled, whose
%              rows are still per-trial-contiguous and in sampleNumber order).
%              NOT used to select a column here — every row's trial/order is
%              already fixed by G.trialIdx; this is cosmetic, naming which
%              axis's bins each row represents, for the log message only.
%
%   X3D        : (nTrials, nBins, nFeatures) — nBins = max bin count across
%                trials; short trials zero-padded at the end
%   trialOrder : (nTrials x 1) — G.trialIdx value for X3D's dim-1 order
%   binLabels  : (nBins x 1) — poolAxis's own per-bin representative value
%                (e.g. ["before";"during";"after"]), taken from whichever
%                trial actually has the full nBins (a short trial's own
%                label set would be incomplete); empty when poolAxis==""
%                or isn't a column of G (reduce-only, no deferred pooling
%                axis)
%
% Worked example — 2 trials, epoch pooling (poolAxis="t"), trial 2 one bin
% short (its "after" epoch happened to round down to zero raw samples),
% 2 reduced features:
%
%   X   = [ 1 10;      G.trialIdx = [1;1;1;2;2]      (5x1)
%           2 20;      G.t        = ["before";"during";"after";
%           3 30;                    "before";"during"]       (5x1)
%           4 40;
%           5 50 ]     <- trial 1's 3 rows, then trial 2's only 2 rows
%        (5x2 = nGroups x nFeatures)
%
%   trialIDs      = [1;1;1;2;2]
%   trialOrder    = [1;2]                    -> nTrials=2
%   nBinsPerTrial = [3;2]                    -> nBins = max = 3 (NOT an error)
%   nFeat=2 -> X3D = zeros(2,3,2)   <- zeros, not nan
%
%   ti=1 (full):  X3D(1,:,:) = X(rows,:) = [1 10; 2 20; 3 30]
%   ti=2 (short): X3D(2,1:2,:) = [4 40; 5 50];  X3D(2,3,:) stays [0 0] (padded)
%
%   binLabels taken from trial 1 (the one with the full 3 bins):
%   ["before";"during";"after"]
    poolAxis = char(poolAxis);
    trialIDs = G.trialIdx;
    trialOrder = unique(trialIDs, 'stable');
    nTrials    = numel(trialOrder);

    nBinsPerTrial = zeros(nTrials, 1);
    for ti = 1:nTrials
        nBinsPerTrial(ti) = nnz(trialIDs == trialOrder(ti));
    end

    nBins = max(nBinsPerTrial);
    nFeat = size(X, 2);
    X3D   = zeros(nTrials, nBins, nFeat);   % zero-padded by default, not nan -- see header
    binLabels = [];

    shortTrials = find(nBinsPerTrial < nBins);
    if ~isempty(shortTrials)
        fprintf(['[nexOp_reshapeStackedByTrial] %d of %d trial(s) came up short on "%s" bins ' ...
                 '(counts: %s, max=%d) -- zero-padding at the end of each short trial''s own ' ...
                 'rows, not trimming every trial down to the shortest.\n'], ...
                numel(shortTrials), nTrials, poolAxis, mat2str(nBinsPerTrial'), nBins);
    end

    for ti = 1:nTrials
        rows  = (trialIDs == trialOrder(ti));
        nHere = nBinsPerTrial(ti);
        X3D(ti, 1:nHere, :) = X(rows, :);
        if isempty(binLabels) && nHere == nBins && poolAxis ~= "" && ismember(poolAxis, G.Properties.VariableNames)
            binLabels = G.(poolAxis)(rows);
        end
    end
end
