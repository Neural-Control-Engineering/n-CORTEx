function extractEXT_SLRT(params, sessionsToExtract, Q)
    extractionLog = params.extrctItms.EXT.extractionLog;    
    [sessionsLeftToExtract, extractionLog] = checkExtractionProgress(extractionLog,sessionsToExtract,'Extract_SLRT');
    sessions = sessionsToExtract.sessions;
    expmntExtractionHndl = str2func(sprintf("extract%s",params.extractCfg.experiment));
    expmntData = expmntExtractionHndl(params, sessionsToExtract, Q);
    % Load/Extract Data Modalities (using timing segmentation from SLRT)
    extMods = [];

    lfp = loadEXT_LFP(slrt.segTimes);
    lfpExt = extractEXT_LFP(lfp);

    ap = loadEXT_AP(slrt.segTimes);
    apExt = extractEXT_AP(ap);

    % Write Extracted Modalities
end