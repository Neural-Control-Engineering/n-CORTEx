function extractRAW(params)
    % process each experiment associated modality for given list of
    % sessions
    extrctModules = params.extrctItms.RAW.extrctModules;
    extrctFields = fieldnames(extrctModules);
    extractionLog = params.extrctItms.RAW.extractionLog;    
    % process RAW datastreams
    for i = 1:length(extrctFields)
        extrctModule = extrctFields{i};
        % extractionLog = updateExtractionLog(extractionLog, sessionLabel, ColName, Value, initVal)
        extrctHndl = str2func(sprintf("extractRAW_%s", extrctModule));
        params.extractCfg.modality = upper(extrctModule);
        extrctHndl(params, params.extrctItms.RAW.sessionsToExtract, params.extrctItms.RAW.extrctModules.(extrctModule).Q);
        % write to extractionLog
        
        % 
    end

    readtable()
    extractionLog = updateExtractionLog(extractionLog, sessionLabel, ColName, Value, initVal)
    % extractionLog(contains(extractionLog.SessionName,exp_template),:).Extracted=1;  
    % writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv",modality)));
    
end