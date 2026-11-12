function nexAudit_fitSWPGridTrace(auditDir, comboDir, comboLabel, trialRow, mdlObj, STAT_combo, ...
        X_reduced, G_reduced, X_pooled, G_pooled, blockColRanges)
% nexAudit_fitSWPGridTrace  Write one trial's data at each reduce-then-pool
% stage — raw, scaled, reduced, pooled, reshaped — as imagesc heatmaps
% (plus a line-plot companion when the feature count is small enough to
% actually read). Extends nexAnalysis_cvPermute's own
% nexAudit_singleTrialTrace (3 stages: raw/reduced/pooled) with a SCALED
% stage, since fitReduce now also standardizes before block-PCA (Nexus
% WIP.md #19) — that intermediate isn't returned by
% fitReduce/getDesignMatrix (only the reduced and pooled stages are, via
% mdlObj.TRAIN.X_reduced/.G_reduced and mdlObj.DM/.TRAIN.G), so it's
% recomputed here instead: a second, side-effect-free nexOp_stackByFTR +
% Scaler.transform call (never a re-fit — mdlObj.Scaler.model is already
% fitted by the time this runs) — cheap and exactly reproduces what
% fitReduce actually used, since both are pure functions of the same
% STAT_combo/mdlObj.Scaler.
%
% Stage 5 (reshaped) re-derives nexOp_reshapeStackedByTrial's own trial-1
% array (what SSM's nexFit_ssm.m actually hands dynamax) from the SAME
% X_pooled/G_pooled already audited at stage 4, and checks it's an exact,
% unpadded-position-preserving copy of that trial's pooled rows — i.e.
% that reconstituting the trial/time array dimension didn't silently
% reorder or corrupt anything relative to the pooled stage already on
% disk (Nexus WIP.md #19 follow-up: zero-padding short trials). Not a
% recomputation from raw — a pure structural check against stage 4.
%
%   comboDir       : combo_<label> directory, relative to auditDir
%   comboLabel     : display label for this CTG combo (or "all")
%   trialRow       : which row of STAT_combo to trace (1 = first trial)
%   mdlObj         : the child/grandchild this combo was fit on — needs
%                    .domain.FTR, .Scaler (already fitted)
%   STAT_combo     : this combo's own TRAIN.STAT (raw, pre-reduce/pool)
%   X_reduced/G_reduced : mdlObj.TRAIN.X_reduced/.G_reduced (post-reduce,
%                         pre-pool)
%   X_pooled/G_pooled   : mdlObj.DM/.TRAIN.G (post-pool, the actual DM)
%   blockColRanges      : mdlObj.FTR_blockColRanges, for region-boundary
%                         lines on the reduced/pooled stages
    traceDir = fullfile(comboDir, 'single_trial_trace');
    ftrAxis  = char(mdlObj.domain.FTR(1));

    % Stage 1: raw. Orientation-normalize to [time x unit] so every stage
    % shares the same [row x feature] convention (mirrors
    % nexAudit_singleTrialTrace's own resolveAxisDim-based normalization).
    ax0    = STAT_combo.ax(trialRow);
    ptr0   = STAT_combo.ptr(trialRow);
    rawDf  = STAT_combo.df{trialRow};
    ftrDim = nexOp_resolveAxisDim(ax0, ptr0, ftrAxis);
    if ~isempty(ftrDim) && ftrDim == 1
        rawDf = rawDf';
    end
    nexAudit_fitSWPGridTrace_plot(auditDir, traceDir, trialRow, 1, 'raw', comboLabel, ...
        rawDf, [], 'raw unit index', 'raw time row');

    % Stage 2: scaled — recomputed, not stashed (see docstring above).
    [X_raw_all, G_raw_all] = nexOp_stackByFTR(STAT_combo, ftrAxis);
    X_raw_all(isnan(X_raw_all)) = 0;
    X_scaled_all = X_raw_all;
    if isstruct(mdlObj.Scaler) && isfield(mdlObj.Scaler, 'model') && ~isempty(mdlObj.Scaler.model)
        X_scaled_all = double(mdlObj.Scaler.model.transform(py.numpy.array(X_raw_all)));
    end
    X_scaled_trial = X_scaled_all(G_raw_all.trialIdx == trialRow, :);
    % Same feature space as raw (scaling doesn't change feature count) —
    % no region-boundary lines here; blockColRanges indexes the REDUCED
    % output's columns, a different width.
    nexAudit_fitSWPGridTrace_plot(auditDir, traceDir, trialRow, 2, 'scaled', comboLabel, ...
        X_scaled_trial, [], 'raw feature index', 'raw time row');

    % Stage 3: reduced (post block-PCA, pre-pool).
    X_reduced_trial = X_reduced(G_reduced.trialIdx == trialRow, :);
    nexAudit_fitSWPGridTrace_plot(auditDir, traceDir, trialRow, 3, 'reduced', comboLabel, ...
        X_reduced_trial, blockColRanges, 'reduced feature index (region blocks separated)', 'raw time row');

    % Stage 4: pooled (the actual DM).
    X_pooled_trial = X_pooled(G_pooled.trialIdx == trialRow, :);
    nexAudit_fitSWPGridTrace_plot(auditDir, traceDir, trialRow, 4, 'pooled', comboLabel, ...
        X_pooled_trial, blockColRanges, 'reduced feature index (region blocks separated)', 'pooled window index');

    % Stage 5: reshaped — same trial's own rows, reconstituted into
    % nexOp_reshapeStackedByTrial's (nTrials, nBins, nFeatures) array and
    % sliced back out at trialRow, then checked against stage 4 directly
    % (not recomputed from raw — X_pooled/G_pooled ARE stage 4's own
    % inputs, so this is a pure structural round-trip check).
    poolAxis = nexOp_resolvePoolAxis(mdlObj.pMap);
    [X3D_all, trialOrder] = nexOp_reshapeStackedByTrial(X_pooled, G_pooled, poolAxis);
    tPos = find(trialOrder == trialRow, 1);
    X_reshaped_trial = reshape(X3D_all(tPos, :, :), size(X3D_all, 2), size(X3D_all, 3));
    nexAudit_fitSWPGridTrace_plot(auditDir, traceDir, trialRow, 5, 'reshaped', comboLabel, ...
        X_reshaped_trial, blockColRanges, 'reduced feature index (region blocks separated)', 'reshaped bin index');

    nReal   = size(X_pooled_trial, 1);
    realPart = X_reshaped_trial(1:nReal, :);
    padPart  = X_reshaped_trial(nReal+1:end, :);
    maxDiff  = max(abs(realPart(:) - X_pooled_trial(:)), [], 'omitnan');
    padIsZero = isempty(padPart) || all(padPart(:) == 0);
    if maxDiff == 0
        realMsg = 'EXACT MATCH';
    else
        realMsg = sprintf('MISMATCH (max|diff|=%.6g)', maxDiff);
    end
    if padIsZero
        padMsg = 'OK (all zero, or this trial was not padded)';
    else
        padMsg = 'MISMATCH (padded rows are NOT all zero)';
    end
    checkTxt = sprintf(['%s — trial %d reshape check\n' ...
        'pooled rows for this trial  : %d\n' ...
        'reshaped rows for this trial: %d (array-wide nBins, may exceed pooled rows if OTHER trials were longer)\n' ...
        'reshaped(1:%d,:) vs pooled  : %s\n' ...
        'reshaped(%d:end,:) padding  : %s\n'], ...
        comboLabel, trialRow, nReal, size(X_reshaped_trial, 1), nReal, realMsg, nReal+1, padMsg);
    nexAudit_writeText(auditDir, fullfile(traceDir, sprintf('trial%d_5_reshape_check.txt', trialRow)), checkTxt);
    if maxDiff ~= 0 || ~padIsZero
        warning('[nexAudit_fitSWPGridTrace] trial %d reshape check FAILED — see %s', ...
            trialRow, fullfile(traceDir, sprintf('trial%d_5_reshape_check.txt', trialRow)));
    else
        fprintf('[nexAudit_fitSWPGridTrace] trial %d reshape check passed (%d real rows, exact match against pooled stage).\n', ...
            trialRow, nReal);
    end
end

function nexAudit_fitSWPGridTrace_plot(auditDir, traceDir, trialRow, stageNum, stageName, comboLabel, X, blockColRanges, xlab, ylab)
    fig = figure('Visible', 'off');
    imagesc(X); colorbar; hold on;
    for b = 1:numel(blockColRanges)
        xline(min(blockColRanges(b).cols) - 0.5, 'w-');
    end
    hold off;
    xlabel(xlab); ylabel(ylab);
    title(sprintf('%s — trial %d — %d: %s', comboLabel, trialRow, stageNum, stageName), 'Interpreter', 'none');
    nexAudit_savePlot(auditDir, fullfile(traceDir, sprintf('trial%d_%d_%s.png', trialRow, stageNum, stageName)), fig);

    nFeat = size(X, 2);
    if nFeat <= 20 && size(X, 1) > 1
        legendLabels = compose("f%d", 1:nFeat);
        fig = figure('Visible', 'off');
        plot(X); xlabel(ylab); ylabel('value');
        title(sprintf('%s — trial %d — %d: %s (lines)', comboLabel, trialRow, stageNum, stageName), 'Interpreter', 'none');
        legend(legendLabels, 'Location', 'eastoutside');
        nexAudit_savePlot(auditDir, fullfile(traceDir, sprintf('trial%d_%d_%s_lines.png', trialRow, stageNum, stageName)), fig);
    end
end
