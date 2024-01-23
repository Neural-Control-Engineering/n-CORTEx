function tbl = initTable(varNames)
     tbl = cell2table(cell(1,length(varNames)), 'VariableNames', varNames);
end