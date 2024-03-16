function extractEXT_SLRT(params, sessionsToExtract, Q)
    extractionLog = params.extrctItms.EXT.extractionLog;    
    [sessionsLeftToExtract, extractionLog] = checkExtractionProgress(extractionLog,sessionsToExtract,'Extract_SLRT');
    sessions = sessionsToExtract.sessions;
    expmntExtractionHndl = str2func(sprintf("extract%s",params.extractCfg.experiment));
    expmntData = expmntExtractionHndl(params, sessionsToExtract, Q);    
end