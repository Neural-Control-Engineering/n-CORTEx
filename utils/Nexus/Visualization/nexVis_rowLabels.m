function [rowLabels, grpCols] = nexVis_rowLabels(RESULT, rowIdx)
% Build composite label strings for RESULTS rows from non-structural columns.
%
% grpCols  — column names that are not DF struct fields
% rowLabels — one ' | '-joined label string per row in rowIdx
    DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","cov","sem","labels"];
    allCols  = string(RESULT.Properties.VariableNames);
    grpCols  = allCols(~ismember(allCols, DF_STRUCT_FIELDS));
    nRows    = numel(rowIdx);
    rowLabels = strings(nRows, 1);
    for ri = 1:nRows
        r     = rowIdx(ri);
        parts = arrayfun(@(c) string(RESULT.(char(grpCols(c)))(r)), ...
            1:numel(grpCols), 'UniformOutput', false);
        rowLabels(ri) = strjoin([parts{:}], ' | ');
    end
end
