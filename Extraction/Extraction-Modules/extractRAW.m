function extractRAW(params)
    % process each experiment associated modality for given list of
    % sessions
    extrctModules = params.extrctItms.RAW.extrctModules;
    extrctFields = fieldnames(extrctModules);
    extractionLog = params.extrctItms.RAW.extractionLog;    
    % process RAW datastreams
    for i = 1:length(extrctFields)
        extrctModule = extrctFields{i};
        extrctHndl = sprintf("extractRAW_%s", extrctModule);
        extrctHndl(params, params.extrctItms.RAW.sessions_to_extract, params.extrctItms.RAW.extractModules.(extrctModule).Q);
        % write to extractionLog
        % extractionLog = updateExtractionLog(extractionLog, sessionLabel, ColName, Value, initVal)
        % 
    end

    readtable()
    extractionLog = updateExtractionLog(extractionLog, sessionLabel, ColName, Value, initVal)
    % extractionLog(contains(extractionLog.SessionName,exp_template),:).Extracted=1;  
    % writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv",modality)));
    
end