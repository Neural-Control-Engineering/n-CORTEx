function nexAudit_section1_compileSTAT(auditDir, STAT_full, tVar)
% nexAudit_section1_compileSTAT  Write the Section 1 (compileSTAT) audit
% record for nexAnalysis_cvPermute's opt-in audit trail (cvCfg.auditDir):
% a shape/column summary plus a histogram of the target variable across
% ALL trials (before any CTG split).
    txt = sprintf(['STAT_full: %d trials\ncolumns: %s\ntarget (tVar): %s\n' ...
                    'trial 1 df shape: %s\ntrial 1 ax fields: %s\n'], ...
                   height(STAT_full), strjoin(STAT_full.Properties.VariableNames, ', '), tVar, ...
                   mat2str(size(STAT_full.df{1})), strjoin(fieldnames(STAT_full.ax(1)), ', '));
    nexAudit_writeText(auditDir, '01_compileSTAT/summary.txt', txt);

    fig = figure('Visible', 'off');
    histogram(STAT_full.(tVar));
    title(sprintf('%s — all %d trials', tVar, height(STAT_full)), 'Interpreter', 'none');
    xlabel(tVar, 'Interpreter', 'none'); ylabel('trial count');
    nexAudit_savePlot(auditDir, '01_compileSTAT/tVar_histogram_all.png', fig);
end
