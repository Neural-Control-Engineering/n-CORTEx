function log = initExtractionLog(params, modality)
    % initiate an extraction log with sessionName column and isExtracted
    % column
    log = array2table(cell(1,length(colNames)),"VariableNames", colNames);
end