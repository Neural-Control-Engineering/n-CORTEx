function fig = plot_mixedEffectPairedComparison(results, stratum, band, chans, t, nexon)
% plot_mixedEffectPairedComparison  Within-subject paired comparison for
% ONE grid cell (band x chans x t) within ONE CCI/side stratum --
% complements plot_mixedEffectViolin's all-subject-pooled view, which can
% look deceptively "noisy" (densely overlapping scatter, even with tight
% SEM bars) whenever between-subject baseline variance is large relative
% to the within-subject condition effect -- exactly what the model's own
% (1|subject) random intercept is already absorbing mathematically. This
% shows that directly instead of just trusting the model did it right.
%
% Two panels:
%   left  : each subject's own RAW mean (not model-fitted -- a
%           model-independent check) at low/high condition, connected by
%           a line -- same per-subject-color convention as
%           plot_mixedEffectTrajectory.m's panels, so the two can be
%           visually cross-checked against each other (this uses actual
%           per-subject means; the trajectory figure's m0/m1/m2 panels
%           use fitlme's shrunk BLUP predictions -- related but distinct
%           quantities, by design).
%   right : each subject's own (high - low) difference, one dot per
%           subject, against a zero reference line -- the direct visual
%           answer to "do these consistently point the same way."
%
% A formal paired test on the per-subject differences is run and
% annotated in the title: paired t-test AND Wilcoxon signed-rank (the
% latter doesn't assume normality, which matters given N is typically
% only 6-10 subjects here -- report both rather than picking one, since
% disagreement between them is itself informative).
%
%   results : the struct run_mixedEffectPipeline returns (uses .T, same
%           as plot_mixedEffectTrajectory.m/plot_mixedEffectViolin.m) --
%           filtered via the SAME stratifyMixedEffectT helper, so this
%           draws from the exact same rows that produced that stratum's
%           build_bandHierarchy output.
%   stratum : one of "preCCI_L","preCCI_R","postCCI_L","postCCI_R".
%   band, chans, t : the one cell to drill into, as values appearing in
%           T's own categorical columns (e.g. "gamma", "STN", "0.967").
%   nexon : optional, default []. Supplies nexon.settings.Colors.cyberGreen
%           as the accent color, matching the other MixedEffect figures;
%           falls back to the same literal startNexus.m seeds it with if
%           omitted.
%
%   fig : the created figure handle.

    if nargin < 6, nexon = []; end

    if ~isfield(results, 'T')
        error('plot_mixedEffectPairedComparison:noT', ...
            'results has no .T field -- expected run_mixedEffectPipeline''s own output struct.');
    end
    strataT = stratifyMixedEffectT(results.T);
    validStrata = ["preCCI_L", "preCCI_R", "postCCI_L", "postCCI_R"];
    if ~ismember(stratum, validStrata)
        error('plot_mixedEffectPairedComparison:badStratum', ...
            'stratum "%s" not recognized -- expected one of: %s.', string(stratum), strjoin(validStrata, ', '));
    end
    T = strataT.(char(stratum));

    mask = T.band == band & T.chans == chans & T.t == t;
    Tc = T(mask, :);
    if height(Tc) == 0
        error('plot_mixedEffectPairedComparison:noRows', ...
            'No rows in stratum "%s" for band="%s", chans="%s", t="%s".', ...
            string(stratum), string(band), string(chans), string(t));
    end
    Tc.subject   = categorical(string(Tc.subject));
    Tc.condition = categorical(string(Tc.condition));
    condLevels = categories(Tc.condition);
    if numel(condLevels) ~= 2
        error('plot_mixedEffectPairedComparison:badCondition', ...
            'Expected exactly 2 condition levels, found %d.', numel(condLevels));
    end
    subjects = unique(Tc.subject);
    nS = numel(subjects);

    % Per-subject RAW means -- only subjects with data at BOTH condition
    % levels contribute a valid pair; a subject missing one side entirely
    % cannot be paired and is dropped (flagged, not silently ignored).
    lowMean  = nan(nS, 1);
    highMean = nan(nS, 1);
    for i = 1:nS
        rowsLow  = Tc.subject == subjects(i) & Tc.condition == condLevels{1};
        rowsHigh = Tc.subject == subjects(i) & Tc.condition == condLevels{2};
        if any(rowsLow),  lowMean(i)  = mean(Tc.bandPower(rowsLow));  end
        if any(rowsHigh), highMean(i) = mean(Tc.bandPower(rowsHigh)); end
    end
    pairedMask = ~isnan(lowMean) & ~isnan(highMean);
    nDropped = nnz(~pairedMask);
    if nDropped > 0
        fprintf(['[plot_mixedEffectPairedComparison] %d/%d subject(s) missing one condition ' ...
                 'entirely -- dropped from the paired test (not silently averaged in).\n'], nDropped, nS);
    end
    subjects_p = subjects(pairedMask);
    lowMean_p  = lowMean(pairedMask);
    highMean_p = highMean(pairedMask);
    diffs      = highMean_p - lowMean_p;
    nPaired    = numel(diffs);
    if nPaired < 3
        error('plot_mixedEffectPairedComparison:tooFewPairs', ...
            'Only %d subject(s) have data at both condition levels -- need >=3 for a paired test.', nPaired);
    end

    [~, p_ttest]  = ttest(diffs);
    try
        p_signrank = signrank(diffs);
    catch
        p_signrank = NaN; % signrank errors on an exactly-symmetric-about-zero edge case with tiny N
    end

    fprintf(['[plot_mixedEffectPairedComparison] %s: band="%s", chans="%s", t="%s" -- %d paired ' ...
             'subject(s), paired t-test p=%.4g, Wilcoxon signrank p=%.4g\n'], ...
        string(stratum), string(band), string(chans), string(t), nPaired, p_ttest, p_signrank);

    DARK_BG = [0.11 0.11 0.13];
    DARK_AX = [0.16 0.16 0.18];
    TEXT_C  = [0.90 0.90 0.90];
    cyberGreen = resolveCyberGreen(nexon);
    subjColors = lines(nPaired);

    fig = figure('Color', DARK_BG, 'Position', [100 100 950 460]);
    tl  = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    % --- left: raw per-subject paired means ---
    ax0 = nexttile(tl);
    hold(ax0, 'on');
    for i = 1:nPaired
        plot(ax0, [1 2], [lowMean_p(i), highMean_p(i)], '-', 'Color', [subjColors(i,:) 0.6], 'LineWidth', 1.2);
        plot(ax0, [1 2], [lowMean_p(i), highMean_p(i)], 'o', 'MarkerFaceColor', subjColors(i,:), ...
            'MarkerEdgeColor', 'none', 'MarkerSize', 7);
        text(ax0, 2.08, highMean_p(i), char(subjects_p(i)), 'Color', subjColors(i,:), ...
            'FontSize', 7, 'Interpreter', 'none');
    end
    plot(ax0, [1 2], [mean(lowMean_p), mean(highMean_p)], '-', 'Color', cyberGreen, 'LineWidth', 3);
    set(ax0, 'XTick', [1 2], 'XTickLabel', cellstr(condLevels), 'XLim', [0.7 2.4], ...
             'Color', DARK_AX, 'XColor', TEXT_C, 'YColor', TEXT_C);
    ylabel(ax0, 'bandPower (raw subject mean)', 'Color', TEXT_C);
    title(ax0, 'per-subject raw means (paired)', 'Color', TEXT_C, 'Interpreter', 'none');
    hold(ax0, 'off');

    % --- right: per-subject differences against zero ---
    ax1 = nexttile(tl);
    hold(ax1, 'on');
    yline(ax1, 0, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    jitter = (rand(nPaired,1) - 0.5) * 0.3;
    for i = 1:nPaired
        plot(ax1, 1 + jitter(i), diffs(i), 'o', 'MarkerFaceColor', subjColors(i,:), ...
            'MarkerEdgeColor', 'none', 'MarkerSize', 9);
    end
    plot(ax1, [0.7 1.3], [mean(diffs), mean(diffs)], '-', 'Color', cyberGreen, 'LineWidth', 2.5);
    set(ax1, 'XTick', 1, 'XTickLabel', {'high - low'}, 'XLim', [0.5 1.5], ...
             'Color', DARK_AX, 'XColor', TEXT_C, 'YColor', TEXT_C);
    ylabel(ax1, 'per-subject difference', 'Color', TEXT_C);
    title(ax1, sprintf('n=%d paired: t-test p=%.3g, signrank p=%.3g', nPaired, p_ttest, p_signrank), ...
          'Color', TEXT_C, 'Interpreter', 'none', 'FontSize', 10);
    hold(ax1, 'off');

    title(tl, sprintf('%s | %s | %s | t=%s', string(stratum), string(band), string(chans), string(t)), ...
          'Color', TEXT_C, 'Interpreter', 'none');
    set(fig, 'InvertHardcopy', 'off');
end

function c = resolveCyberGreen(nexon)
% resolveCyberGreen  nexon.settings.Colors.cyberGreen when available,
% falling back to the same literal startNexus.m seeds it with so this
% figure matches the other MixedEffect figures' accent color even without
% a live nexon.
    c = [0.24, 0.94, 0.46];
    if isempty(nexon), return; end
    try
        c = nexon.settings.Colors.cyberGreen;
    catch
    end
end
