function writeBatchSample(batchPath, sample, foldNum, sampleNum, labelIDs, labelVals)
    % write sample to designated fold folder
    sampleTag = sprintf("%0*d.csv",10,sampleNum); % sample identifier             
    foldID = sprintf("Fold%d",foldNum);
    samplePath = fullfile(batchPath,foldID);
    buildPath(samplePath);
    writematrix(sample,fullfile(samplePath,sampleTag));       

    % generate/append sampleID vector to index file
    index_file = fullfile(batchPath, 'index.csv');    
    indexCols = cellstr(["sampleTag","fold",labelIDs]);
    A_row = [sampleTag, foldNum, labelVals'];

    % Append Y to Y.csv (with column headers if missing)
    if isfile(index_file)
        % If the file exists, just append the data
        % Create a table for the data with headers
        index_table = array2table(A_row, 'VariableNames', indexCols);
        writetable(index_table, index_file, 'WriteMode', 'append');
    else
        % If the file doesn't exist, write the headers and data
        % Create a table for the data with headers
        index_table = array2table(A_row, 'VariableNames', indexCols);
        writetable(index_table, index_file);
    end
end