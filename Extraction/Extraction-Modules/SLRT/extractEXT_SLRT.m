function extractEXT_SLRT(params, sessionsToExtract, Q)
    extractionLog = params.extrctItms.EXT.extractionLog;    
    [sessionsLeftToExtract, extractionLog] = checkExtractionProgress(extractionLog,sessionsToExtract,'Extract_SLRT');
    sessions = sessionsToExtract.sessions;
    expmntExtractionHndl = str2func(sprintf("extract%s",params.extractCfg.experiment));
    expmntData = expmntExtractionHndl(params, sessionsToExtract, Q);    
    % exportExpmntData(expmntData,Q);
    
    % for i = 1:length(sessions)
    %     sessionLabel = sessions{i};
    %     % load relevant data
    %     % expmntData = struct;
    %     % expmntData = loadDataModalities(params, sessionLabel, struct, params.extrctItms.EXT.extrctModules, 'EXT');
    %     % process experiment (with modality inputs/outputs)
    %     expmntExtractionHndl = str2func(sprintf("extract%s",params.extractCfg.experiment));
    %     expmntData = expmntExtractionHndl(params, expmntData, Q);
    %     % export/extract relevant data to associated folders
    %     % expmntData = extractExpmntFields(expmntData,Q);
    %     LFP = [LFP; extractEXT_LFP(params, sessionLabel, expmntData.LFP, Q)];
    %     SLRT = [SLRT; expmntData.SLRT];
    %     extractionLog(contains(extractionLog.SessionName,sessionLabel),:).Extracted = 1;
    % end      
end