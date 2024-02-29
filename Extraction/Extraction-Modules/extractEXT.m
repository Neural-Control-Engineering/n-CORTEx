function extractEXT(params)
    % process each experiment associated modality for given list of
    % sessions
    extrctModules = params.extrctItms.EXT.extrctModules;
    extrctFields = fieldnames(extrctModules);
    extractionLog = params.extrctItms.EXT.extractionLog;    
    % process datastreams relative to SLRT

    % sessionsLeftToExtract = checkExtractionProgress(extractionLog, params.extrctItms.EXT.sessionsToExtract, "Extract_slrt");    
    extractEXT_SLRT(params, params.extrctItms.EXT.sessionsToExtract, params.extrctItms.EXT.extrctModules.SLRT.Q);

    % for i = 1:length(extrctFields)
    %     extrctModule = extrctFields{i};        
    %     extrctHndl = str2func(sprintf("extractEXT_%s", extrctModule));
    %     params.extractCfg.modality = upper(extrctModule);
    %     sessionsLeftToExtract = checkExtractionProgress(extractionLog, params.extrctItms.EXT.sessionsToExtract, extrctModule);
    %     extrctHndl(params, sessionsLeftToExtract, params.extrctItms.EXT.extrctModules.(extrctModule).Q);      
    % end
    % Final mark of completed extraction for ext layer
    extractionLog = readtable(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","EXT")));
    extractionLog(contains(extractionLog.SessionName,(params.extrctItms.EXT.sessionsToExtract.sessions)),:).Extracted = ones(height(params.extrctItms.EXT.sessionsToExtract.sessions),1);       
    writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","EXT")));
end