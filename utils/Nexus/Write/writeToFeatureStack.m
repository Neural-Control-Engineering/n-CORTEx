function writeToFeatureStack(stackPath, X, Y, labelIDs, labelKeys)
    % append X-row to X.csv (if not already existing, create a new one)
    % append Y-row to Y.csv (if not already existifunction appendToFeatureStack(stackPath, X, Y, labelIDs)
    % Ensure stackPath exists
    if ~isfolder(stackPath)
        mkdir(stackPath);
    end
    
    % Define file paths
    X_file = fullfile(stackPath, 'X.csv');
    Y_file = fullfile(stackPath, 'Y.csv');
    labelKey_file = fullfile(stackPath,"labelKeys.json");

    % Append X to X.csv (Create if missing)
    if isfile(X_file)
        writematrix(X, X_file, 'WriteMode', 'append');
    else
        writematrix(X, X_file);
    end

    % Append Y to Y.csv (with column headers if missing)
    if isfile(Y_file)
        % If the file exists, just append the data
        % Create a table for the data with headers
        Y_table = array2table(Y, 'VariableNames', labelIDs);
        writetable(Y_table, Y_file, 'WriteMode', 'append');
    else
        % If the file doesn't exist, write the headers and data
        % Create a table for the data with headers
        Y_table = array2table(Y, 'VariableNames', labelIDs);
        writetable(Y_table, Y_file);
    end

    if ~isfile(labelKey_file)
        exportLabelKeys(labelKeys, labelKey_file);
    end
end