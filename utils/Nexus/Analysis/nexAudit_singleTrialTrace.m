function nexAudit_singleTrialTrace(auditDir, comboDir, ctgLabel, trialRow, rawDf, ...
        X_full_r, G_full, X_full_p, G_full_p, blockColRanges_full)
% nexAudit_singleTrialTrace  Write one trial's data at each transform
% stage — raw, post block-PCA reduction, post-pooling — as imagesc
% heatmaps (plus a polyGraph-style line-plot companion when the channel
% count is small enough to actually read). Traced through the full-CTG
% refit (one canonical basis for the whole combo), not any individual
% fold's own basis — a fold's basis depends on which other trials
% happened to be in that fold's training set, a different question from
% "is the transform pipeline itself clobbering data."
%
%   rawDf  : this trial's raw df, ALREADY normalized to [time x unit]
%            orientation by the caller (see resolveAxisDim there — kept
%            out of this file since resolveAxisDim is a local function
%            private to nexAnalysis_cvPermute.m).
%   X_full_r/G_full     : fitReduce's stacked-and-reduced output + its
%                         companion row table (G_full.trialIdx selects
%                         this trial's own rows).
%   X_full_p/G_full_p   : nexOp_poolStackedDM's pooled output + companion
%                         table, same trialIdx convention.
%   blockColRanges_full : fitReduce's per-region column ranges, used to
%                         draw region-boundary separator lines.
    traceDir = fullfile(comboDir, 'single_trial_trace');

    fig = figure('Visible', 'off');
    imagesc(rawDf); colorbar;
    xlabel('raw unit index'); ylabel('raw time row');
    title(sprintf('%s — trial %d — 1: raw', ctgLabel, trialRow), 'Interpreter', 'none');
    nexAudit_savePlot(auditDir, fullfile(traceDir, sprintf('trial%d_1_raw.png', trialRow)), fig);

    X2 = X_full_r(G_full.trialIdx == trialRow, :);
    fig = figure('Visible', 'off');
    imagesc(X2); colorbar; hold on;
    for b = 1:numel(blockColRanges_full)
        xline(min(blockColRanges_full(b).cols) - 0.5, 'w-');
    end
    hold off;
    xlabel('reduced feature index (region blocks separated)'); ylabel('raw time row');
    title(sprintf('%s — trial %d — 2: post block-PCA reduction', ctgLabel, trialRow), 'Interpreter', 'none');
    nexAudit_savePlot(auditDir, fullfile(traceDir, sprintf('trial%d_2_reduced.png', trialRow)), fig);

    X3 = X_full_p(G_full_p.trialIdx == trialRow, :);
    fig = figure('Visible', 'off');
    imagesc(X3); colorbar; hold on;
    for b = 1:numel(blockColRanges_full)
        xline(min(blockColRanges_full(b).cols) - 0.5, 'w-');
    end
    hold off;
    xlabel('reduced feature index (region blocks separated)'); ylabel('pooled window index');
    title(sprintf('%s — trial %d — 3: post-pooling', ctgLabel, trialRow), 'Interpreter', 'none');
    nexAudit_savePlot(auditDir, fullfile(traceDir, sprintf('trial%d_3_pooled.png', trialRow)), fig);

    % polyGraph-style companion — only when few enough channels to
    % actually read as separate lines (e.g. reducerDim=1 across ~15
    % regions = 15 lines; reducerDim=10 = 150, which would just be noise,
    % so skipped automatically above that threshold).
    nReducedFeatures = size(X2, 2);
    if nReducedFeatures <= 20
        legendLabels = compose("f%d", 1:nReducedFeatures);
        fig = figure('Visible', 'off');
        plot(X2); xlabel('raw time row'); ylabel('component value');
        title(sprintf('%s — trial %d — 2 (lines)', ctgLabel, trialRow), 'Interpreter', 'none');
        legend(legendLabels, 'Location', 'eastoutside');
        nexAudit_savePlot(auditDir, fullfile(traceDir, sprintf('trial%d_2_reduced_lines.png', trialRow)), fig);

        fig = figure('Visible', 'off');
        plot(X3); xlabel('pooled window index'); ylabel('component value');
        title(sprintf('%s — trial %d — 3 (lines)', ctgLabel, trialRow), 'Interpreter', 'none');
        legend(legendLabels, 'Location', 'eastoutside');
        nexAudit_savePlot(auditDir, fullfile(traceDir, sprintf('trial%d_3_pooled_lines.png', trialRow)), fig);
    end
end
