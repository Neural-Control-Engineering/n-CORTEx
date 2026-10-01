function nexAudit_comboSummary(auditDir, comboDir, ci, nCombos, ctgLabel, nTrials, tVar, tVarVals)
% nexAudit_comboSummary  Write the Section 5a (per-CTG-combo subset) audit
% record — trial count plus a histogram of the target variable restricted
% to this combo (compare against 01_compileSTAT's all-trials histogram to
% see whether the target distribution differs meaningfully between
% combos, e.g. between two conditions/groups).
    txt = sprintf('combo %d/%d: %s\nnTrials: %d\n', ci, nCombos, ctgLabel, nTrials);
    nexAudit_writeText(auditDir, fullfile(comboDir, 'summary.txt'), txt);

    fig = figure('Visible', 'off');
    histogram(tVarVals);
    title(sprintf('%s — %s (%d trials)', tVar, ctgLabel, nTrials), 'Interpreter', 'none');
    xlabel(tVar, 'Interpreter', 'none'); ylabel('trial count');
    nexAudit_savePlot(auditDir, fullfile(comboDir, 'tVar_histogram.png'), fig);
end
