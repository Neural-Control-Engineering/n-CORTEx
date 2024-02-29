function extractEXT_slrt(params, sessionsToExtract, Q)
    extractionLog = params.extrctItms.EXT.extractionLog;    
    [sessionsLeftToExtract, extractionLog] = checkExtractionProgress(extractionLog,sessionsToExtract,'Extract_slrt');
    sessions = sessionsToExtract.sessions;
    for i = 1:length(sessions)
        sessionLabel = sessions{i};
        % load relevant data
        % expmntData = struct;
        expmntData = loadDataModalities(params, sessionLabel, struct, params.extrctItms.EXT.extrctModules, 'EXT');
        % process experiment (with modality inputs/outputs)
        expmntExtractionHndl = str2func(sprintf("extract%s",params.extractCfg.experiment));
        expmntData = expmntExtractionHndl(params, expmntData, Q);
        % export relevant data to associated folders
    end

end