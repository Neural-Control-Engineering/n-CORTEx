function nexAudit_section2_ctgCombos(auditDir, comboTbl, nCombos, nTrialsTotal)
% nexAudit_section2_ctgCombos  Write the Section 2 (CTG combo enumeration)
% audit record — the full comboTbl (or a note that there's a single
% "all data" combo when no CTG columns are active).
    if isempty(comboTbl)
        txt = sprintf('No CTG columns — single "all data" combo (%d trials).\n', nTrialsTotal);
    else
        txt = evalc('disp(comboTbl)');
        txt = sprintf('%d CTG combos:\n%s', nCombos, txt);
    end
    nexAudit_writeText(auditDir, '02_ctg_combos/combos.txt', txt);
end
