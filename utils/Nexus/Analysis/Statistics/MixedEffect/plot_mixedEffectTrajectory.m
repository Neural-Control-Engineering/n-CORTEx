function fig = plot_mixedEffectTrajectory(results, stratum, band, chans, t, nexon)
% plot_mixedEffectTrajectory  Per-subject intercept/slope progression
% across the m0 -> m1 -> m2 mixed-model hierarchy, for ONE grid cell
% (band x chans x t) within ONE CCI/side stratum. Refits all three models
% on-demand for just this one cell (cheap) rather than retaining fitted
% model objects from a full build_bandHierarchy grid run (850+ cells --
% not worth the memory).
%
% Three panels, left to right, same subject color consistent across all
% three so a single subject's progression is traceable by eye:
%   m0 : per-subject predicted value (random-intercept BLUP), no
%        condition -- pure between-subject baseline spread. Dashed
%        cyberGreen line marks the grand mean (m0's fixed intercept).
%   m1 : per-subject predicted value at low/high condition, connected by
%        a line -- every per-subject line has the SAME slope by
%        construction (m1 has no random slope term); the bold cyberGreen
%        line is the shared fixed effect every subject's line parallels.
%   m2 : same two points per subject, but genuinely non-parallel lines --
%        each subject's own low-to-high shift, visualizing heterogeneity
%        directly instead of only as a reported variance number.
%
%   results : the struct run_mixedEffectPipeline returns (has .T, the
%           full unstratified long-format table, plus the saved/reloaded
%           results you already keep around -- this function only needs
%           .T; it re-derives the same stratum split
%           run_mixedEffectPipeline itself used via stratifyMixedEffectT,
%           so it filters the EXACT same rows that produced that
%           stratum's build_bandHierarchy output, never a second,
%           independently-filtered subset).
%   stratum : one of "preCCI_L","preCCI_R","postCCI_L","postCCI_R".
%   band, chans, t : the one cell to drill into, as values appearing in
%           T's own categorical columns (e.g. "gamma", "VPM", "0.988").
%   nexon : optional, default []. Supplies nexon.settings.Colors.cyberGreen
%           as the accent color, matching plot_bandHierarchyGrid's
%           convention; falls back to the same literal startNexus.m seeds
%           it with if omitted.
%
%   fig : the created figure handle.

    if nargin < 6, nexon = []; end

    if ~isfield(results, 'T')
        error('plot_mixedEffectTrajectory:noT', 'results has no .T field -- expected run_mixedEffectPipeline''s own output struct.');
    end
    strataT = stratifyMixedEffectT(results.T);
    validStrata = ["preCCI_L", "preCCI_R", "postCCI_L", "postCCI_R"];
    if ~ismember(stratum, validStrata)
        error('plot_mixedEffectTrajectory:badStratum', ...
            'stratum "%s" not recognized -- expected one of: %s.', string(stratum), strjoin(validStrata, ', '));
    end
    T = strataT.(char(stratum));

    mask = T.band == band & T.chans == chans & T.t == t;
    Tc = T(mask, :);
    if height(Tc) == 0
        error('plot_mixedEffectTrajectory:noRows', ...
            'No rows in stratum "%s" for band="%s", chans="%s", t="%s".', ...
            string(stratum), string(band), string(chans), string(t));
    end
    % Fresh categorical conversion -- strips any unused category levels
    % inherited from T's full (unfiltered) column, so unique()/categories()
    % below only ever sees subjects/conditions actually present in THIS cell.
    Tc.subject   = categorical(string(Tc.subject));
    Tc.condition = categorical(string(Tc.condition));
    subjects   = unique(Tc.subject);
    condLevels = categories(Tc.condition);
    nS = numel(subjects);
    if height(Tc) < 10 || nS < 2 || numel(condLevels) ~= 2
        error('plot_mixedEffectTrajectory:tooLittleData', ...
            ['Stratum "%s", cell band="%s", chans="%s", t="%s" has %d row(s), %d subject(s), %d ' ...
             'condition level(s) -- need >=10 rows, >=2 subjects, exactly 2 condition levels.'], ...
            string(stratum), string(band), string(chans), string(t), height(Tc), nS, numel(condLevels));
    end

    fprintf(['[plot_mixedEffectTrajectory] %s: fitting m0/m1/m2 for band="%s", chans="%s", t="%s" ' ...
             '(%d rows, %d subjects)...\n'], string(stratum), string(band), string(chans), string(t), height(Tc), nS);

    m0 = fitlme(Tc, 'bandPower ~ 1 + (1|subject)');
    m1 = fitlme(Tc, 'bandPower ~ 1 + condition + (1|subject)');
    m2 = fitlme(Tc, 'bandPower ~ 1 + condition + (1 + condition|subject)');

    % Per-subject fitted values via predict() (random effects included by
    % default) rather than hand-combining fixed+random coefficients --
    % lets fitlme's own machinery handle the algebra.
    Tnew0 = table(subjects, 'VariableNames', {'subject'});
    yhat_m0 = predict(m0, Tnew0);

    subjRep = repelem(subjects, 2, 1);
    condRep = repmat(categorical(condLevels, condLevels), nS, 1);
    Tnew12  = table(subjRep, condRep, 'VariableNames', {'subject', 'condition'});
    yhat_m1 = reshape(predict(m1, Tnew12), 2, nS)';   % col1=low, col2=high
    yhat_m2 = reshape(predict(m2, Tnew12), 2, nS)';

    conditionEffect = m1.Coefficients.Estimate(contains(m1.Coefficients.Name, 'condition'));
    slopes_m2 = yhat_m2(:,2) - yhat_m2(:,1);

    DARK_BG = [0.11 0.11 0.13];
    DARK_AX = [0.16 0.16 0.18];
    TEXT_C  = [0.90 0.90 0.90];
    cyberGreen = resolveCyberGreen(nexon);
    subjColors = lines(nS);

    fig = figure('Color', DARK_BG, 'Position', [100 100 1150 430]);
    tl  = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

    % --- m0: random-intercept spread ---
    ax0 = nexttile(tl);
    hold(ax0, 'on');
    grandMean0 = m0.Coefficients.Estimate(1);
    yline(ax0, grandMean0, '--', 'Color', cyberGreen, 'LineWidth', 1.5);
    for i = 1:nS
        plot(ax0, 1, yhat_m0(i), 'o', 'MarkerFaceColor', subjColors(i,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 8);
        text(ax0, 1.08, yhat_m0(i), char(subjects(i)), 'Color', subjColors(i,:), 'FontSize', 7, 'Interpreter', 'none');
    end
    set(ax0, 'XTick', 1, 'XTickLabel', {'intercept'}, 'XLim', [0.6 1.6], ...
             'Color', DARK_AX, 'XColor', TEXT_C, 'YColor', TEXT_C);
    ylabel(ax0, 'bandPower', 'Color', TEXT_C);
    title(ax0, sprintf('m0 (grand mean = %.3g)', grandMean0), 'Color', TEXT_C, 'Interpreter', 'none');
    hold(ax0, 'off');

    % --- m1: shared fixed slope, parallel by construction ---
    ax1 = nexttile(tl);
    hold(ax1, 'on');
    for i = 1:nS
        plot(ax1, [1 2], yhat_m1(i,:), '-', 'Color', [subjColors(i,:) 0.5], 'LineWidth', 1);
        plot(ax1, [1 2], yhat_m1(i,:), 'o', 'MarkerFaceColor', subjColors(i,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 6);
    end
    plot(ax1, [1 2], [mean(yhat_m1(:,1)), mean(yhat_m1(:,2))], '-', 'Color', cyberGreen, 'LineWidth', 3);
    set(ax1, 'XTick', [1 2], 'XTickLabel', cellstr(condLevels), 'XLim', [0.7 2.3], ...
             'Color', DARK_AX, 'XColor', TEXT_C, 'YColor', TEXT_C);
    title(ax1, sprintf('m1 (fixed effect = %.3g)', conditionEffect), 'Color', TEXT_C, 'Interpreter', 'none');
    hold(ax1, 'off');

    % --- m2: per-subject slopes, genuinely non-parallel ---
    ax2 = nexttile(tl);
    hold(ax2, 'on');
    for i = 1:nS
        plot(ax2, [1 2], yhat_m2(i,:), '-', 'Color', [subjColors(i,:) 0.6], 'LineWidth', 1.2);
        plot(ax2, [1 2], yhat_m2(i,:), 'o', 'MarkerFaceColor', subjColors(i,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 6);
    end
    plot(ax2, [1 2], [mean(yhat_m2(:,1)), mean(yhat_m2(:,2))], '-', 'Color', cyberGreen, 'LineWidth', 3);
    set(ax2, 'XTick', [1 2], 'XTickLabel', cellstr(condLevels), 'XLim', [0.7 2.3], ...
             'Color', DARK_AX, 'XColor', TEXT_C, 'YColor', TEXT_C);
    title(ax2, sprintf('m2 (per-subject slopes: %.3g to %.3g)', min(slopes_m2), max(slopes_m2)), ...
          'Color', TEXT_C, 'Interpreter', 'none');
    hold(ax2, 'off');

    linkaxes([ax0, ax1, ax2], 'y');
    title(tl, sprintf('%s | %s | %s | t=%s', string(stratum), string(band), string(chans), string(t)), ...
          'Color', TEXT_C, 'Interpreter', 'none');
    set(fig, 'InvertHardcopy', 'off');
end

function c = resolveCyberGreen(nexon)
% resolveCyberGreen  nexon.settings.Colors.cyberGreen when available,
% falling back to the same literal startNexus.m seeds it with so this
% figure matches the Nexus brand accent color even without a live nexon.
    c = [0.24, 0.94, 0.46];
    if isempty(nexon), return; end
    try
        c = nexon.settings.Colors.cyberGreen;
    catch
    end
end
