function exportLabelKeys(labelKeys, filePath)
    % EXPORTLABELKEYS Exports a MATLAB struct as a JSON file.
    % labelKeys: A struct where each entry is another struct with key-value pairs.
    % filePath: Full path to the JSON file to save.

    % Convert struct to JSON format
    jsonStr = jsonencode(labelKeys, 'PrettyPrint', true); 
    
    % Write JSON to file
    fid = fopen(filePath, 'w');
    if fid == -1
        error('Cannot open file: %s', filePath);
    end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);
end