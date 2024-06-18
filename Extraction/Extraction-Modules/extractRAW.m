function extractRAW(params)
    % process each experiment associated modality for given list of
    % sessions
    extrctModules = params.extrctItms.RAW.extrctModules;
    extrctFields = fieldnames(extrctModules);
    extractionLog = params.extrctItms.RAW.extractionLog;    
    % process RAW datastreams
    for i = 1:length(extrctFields)
        extrctModule = extrctFields{i};        
        extrctHndl = str2func(sprintf("extractRAW_%s", extrctModule));
        params.extractCfg.modality = upper(extrctModule);
        sessionsLeftToExtract = checkExtractionProgress(extractionLog, params.extrctItms.RAW.sessionsToExtract, extrctModule);        
        extrctHndl(params, sessionsLeftToExtract, params.extrctItms.RAW.extrctModules.(extrctModule).Q);              
    end
    % Final mark of completed extraction for raw layer
    extractionLog = readtable(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","RAW")));
    extractionLog(contains(extractionLog.SessionName,(params.extrctItms.RAW.sessionsToExtract.sessions)),:).Extracted = ones(height(params.extrctItms.RAW.sessionsToExtract.sessions),1);       
    writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","RAW")));
end