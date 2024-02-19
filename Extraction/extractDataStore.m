function extractDataStore(params, location, subjects)
    
    % Extraction Filtering    
    extractionLog = readtable(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs","Feature_extraction_log.csv"),"Delimiter",",");
    sessionsToExtract = extractionLog(extractionLog.Extracted == 0);
    blockSize = params.extractCfg.dataStoreCfg.blockSize;
    dataStore_tall = datastore(location);
    subjectsCondition = any(contains(dataStore_tall.subjectName, subjects));        
    sessionsCondition = any(contains(dataStore_tall.sessionName, sessionsToExtract));
    dataStoreToExtract_tall = dataStore_tall(subjectsCondition & sessionsCondition);

    % Tall Iteration
    dsLen = gather(size(dataStoreToExtract_tall,1));
    numItr = floor(dsLen / blockSize);
    rem = mod(dsLen, blockSize);
    strt = 1;
    for i = (numItr + 1)
        if i == numItr + 1;
            brk = strt + rem - 1;
        else
            brk = i * blockSize;
        end
        rowSelect = dataStoreToExtract_tall((strt : brk), :);
        dataStore = gather(rowSelect);

        % RUN EXPERIMENT-SPECIFIC FEATURE EXTRACTION
        cmd = sprintf("featureExtract = extractFeature_%s(params, dataStore);", params.extractCfg.experiment);
        eval(cmd);

        strt = brk + 1;
    end

end