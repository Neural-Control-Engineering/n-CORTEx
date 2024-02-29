function extractEXT_npxls(params, sessionsToExtract, Q)
    modality = params.extractCfg.modality;    
    sessions = sessionsToExtract.sessions;
    for i = 1:length(sessions)
        sessionLabel = sessions{i};
        lfpExtract = extractLFP(sessionLabel);
    end
end