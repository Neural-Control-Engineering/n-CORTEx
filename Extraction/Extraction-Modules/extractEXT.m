function extractEXT(params)
    % process each experiment associated modality for given list of
    % sessions
    extrctModules = params.extrctItms.EXT.extrctModules;
    extrctFields = fieldnames(extrctModules);
    extractionLog = params.extrctItms.EXT.extractionLog;    
    % process datastreams relative to SLRT
    
    % extractEXT_SLRT(params, params.extrctItms.EXT.sessionsToExtract, params.extrctItms.EXT.extrctModules.SLRT.Q);

    sessions = params.extrctItms.EXT.sessionsToExtract.sessions;
    switch params.extractCfg.experiment
        case 'JOLT'
            sessionsLeftToExtract = checkExtractionProgress(extractionLog, params.extrctItms.EXT.sessionsToExtract, "Extract_slrt");    
            Q = params.extrctItms.EXT.Q;
            extractJOLT(params, sessionsLeftToExtract, Q);
        otherwise
            numSessions = size(sessions,1);
            for i = 1:numSessions
                session = sessions{i};
                slrtFile = fullfile(params.paths.Data.RAW.SLRT.cloud,session);
                SLRT = extractEXT_SLRT(slrtFile);
        
                extrctModules = params.extrctItms.EXT.extrctModules;
                extModNames = fieldnames(extrctModules);
                extData = struct;
                for j = 1:length(extModNames)
                    extMod = extModNames{j};
                    extrctHndl = str2func(sprintf("extractEXT_%s", extrctModule));                        
                    try
                        extData.(extMod) = extrctHndl(SLRT, params.paths.Data);
                        extModPath = fullfile(params.paths.Data.EXT.(extMod).cloud,sprintf("%s.mat",session));
                        save(extModPath,extData.(extMod));
                    catch e
                        disp(e);
                    end         
                end
            end
    end
   
    % Final mark of completed extraction for ext layer
    extractionLog = readtable(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","EXT")));
    extractionLog(contains(extractionLog.SessionName,(params.extrctItms.EXT.sessionsToExtract.sessions)),:).Extracted = ones(height(params.extrctItms.EXT.sessionsToExtract.sessions),1);       
    writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","EXT")));


end