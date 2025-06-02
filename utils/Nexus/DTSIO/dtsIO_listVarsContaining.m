function vars = dtsIO_listVarsContaining(DTS,DFID)
    tableVars = convertCharsToStrings(DTS.Properties.VariableNames);
    idx_matchingVars = contains(tableVars,DFID);
    vars = tableVars(idx_matchingVars);
end