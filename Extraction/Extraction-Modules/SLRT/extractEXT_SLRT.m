function extractEXT_SLRT(params, sessionsToExtract, Q)
    extractionLog = params.extrctItms.EXT.extractionLog;    
    [sessionsLeftToExtract, extractionLog] = checkExtractionProgress(extractionLog,sessionsToExtract,'Extract_SLRT');
    sessions = sessionsToExtract.sessions;
    expmntExtractionHndl = str2func(sprintf("extract%s",params.extractCfg.experiment));
    for i = 1:length(sessions)
        session = sessions{i};
        slrtExt = expmntExtractionHndl(params, session, Q);
        % Load/Extract Data Modalities (using timing segmentation from SLRT)
        extMods = fieldnames(params.extrctItms.EXT.extrctModules);
    
        % lfp = loadEXT_LFP(params, session, slrtExt.segTimes);
        LFP = loadEXT_LFP(params, session);
        lfpExt = extractEXT_LFP(params, LFP);
    
        ap = loadEXT_AP(slrt.segTimes);
        apExt = extractEXT_AP(ap);

        % Write Extracted Modalities
    end    
    
end