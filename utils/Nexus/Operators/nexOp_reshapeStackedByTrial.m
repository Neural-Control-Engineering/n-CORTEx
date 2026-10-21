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
%   X        : (nGroups, nFeatures) — e.g. mdlObj.DM (needsHR "stack" format)
%   G        : companion table, nGroups tall, with a .trialIdx column
%              (mdlObj.TRAIN.G's own shape)
%   poolAxis : pool axis name (char/string), or "" if this needsHR mdlObj
%              has no designated pool-mode axis (reduce-only — getDesignMatrix
%              then sets G to fitReduce's own raw-stacked G, un-pooled, whose
%              rows are still per-trial-contiguous and in sampleNumber order).
%              NOT used to select a column here — every row's trial/order is
%              already fixed by G.trialIdx; this is cosmetic, naming which
%              axis's bins each row represents, for the error message only.
%
%   X3D        : (nTrials, nBins, nFeatures)
%   trialOrder : (nTrials x 1) — G.trialIdx value for X3D's dim-1 order
%   binLabels  : (nBins x 1) — poolAxis's own per-bin representative value
%                (e.g. ["before";"during";"after"]), taken from trial 1's
%                own rows (identical for every trial since nBins is
%                enforced uniform above); empty when poolAxis=="" or isn't
%                a column of G (reduce-only, no deferred pooling axis)
%
% Worked example — 2 trials, epoch pooling (poolAxis="t", 3 bins/trial:
% before/during/after), 2 reduced features:
%
%   X   = [ 1 10;      G.trialIdx = [1;1;1;2;2;2]    (6x1)
%           2 20;      G.t        = ["before";"during";"after";
%           3 30;                    "before";"during";"after"]  (6x1)
%           4 40;
%           5 50;      <- trial 1's 3 rows, then trial 2's 3 rows,
%           6 60 ]         each already in before/during/after order
%        (6x2 = nGroups x nFeatures)
%
%   trialIDs   = G.trialIdx = [1;1;1;2;2;2]
%   trialOrder = unique(trialIDs,'stable') = [1;2]        -> nTrials=2
%   nBinsPerTrial = [nnz(trialIDs==1); nnz(trialIDs==2)] = [3;3]
%     -> numel(unique([3;3]))==1, so NOT ragged -> proceed (would ERROR
%        here instead if trial 2 only had 2 bins, e.g. [3;2])
%   nBins=3, nFeat=2 -> X3D = nan(2,3,2)
%
%   ti=1: rows = (trialIDs==1) = [1;1;1;0;0;0] (logical)
%         X3D(1,:,:) = X(rows,:) = [1 10; 2 20; 3 30]   <- this trial's
%                                                           3 epoch rows
%   ti=2: rows = (trialIDs==2) = [0;0;0;1;1;1]
%         X3D(2,:,:) = X(rows,:) = [4 40; 5 50; 6 60]
%
%   Result: X3D(1,:,:) squeezed = [1 10; 2 20; 3 30]  (trial 1's before/during/after)
%           X3D(2,:,:) squeezed = [4 40; 5 50; 6 60]  (trial 2's before/during/after)
%           size(X3D) = [2 3 2]  — exactly the (num_trials, T, emission_dim)
%           shape dynamax's batched fit_em/filter expect (see pytafix's
%           lgssm_dynamax.py and the installed dynamax ssm.py).
    poolAxis = char(poolAxis);
    trialIDs = G.trialIdx;
    trialOrder = unique(trialIDs, 'stable');
    nTrials    = numel(trialOrder);

    nBinsPerTrial = zeros(nTrials, 1);
    for ti = 1:nTrials
        nBinsPerTrial(ti) = nnz(trialIDs == trialOrder(ti));
    end
    if numel(unique(nBinsPerTrial)) > 1
        error('nexOp_reshapeStackedByTrial:ragged', ...
            ['Trials have different pooled "%s" bin counts (%s) -- cannot reshape into ' ...
             'a rectangular (nTrials, nBins, nFeatures) array. Every trial must produce ' ...
             'the same number of bins (true by construction for the "epoch" mapID default ' ...
             '-- see Nexus WIP.md #16/#19 -- but not a general guarantee for every pMap config).'], ...
            poolAxis, mat2str(unique(nBinsPerTrial)'));
    end

    nBins = nBinsPerTrial(1);
    nFeat = size(X, 2);
    X3D   = nan(nTrials, nBins, nFeat);
    binLabels = [];
    for ti = 1:nTrials
        rows = (trialIDs == trialOrder(ti));
        X3D(ti, :, :) = X(rows, :);
        if ti == 1 && poolAxis ~= "" && ismember(poolAxis, G.Properties.VariableNames)
            binLabels = G.(poolAxis)(rows);
        end
    end
end
