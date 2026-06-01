function DF = nexVis_rowToDF(RESULT, rowIdx)
% Extract a single RESULTS table row as a plain DF struct.
    row    = RESULT(rowIdx, :);
    DF.df  = row.df{1};
    DF.ax  = row.ax{1};
    DF.ptr = row.ptr{1};
    if ismember('sem', RESULT.Properties.VariableNames) && ~isempty(row.sem{1})
        DF.sem = row.sem{1};
    end
end
