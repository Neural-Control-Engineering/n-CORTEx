function extractEXT(params)
    % process each experiment associated modality for given list of
    % sessions
    extrctModules = params.extrctItms.EXT.extrctModules;
    extrctFields = fieldnames(extrctModules);
    extractionLog = params.extrctItms.EXT.extractionLog;    
    % process datastreams relative to SLRT

    % sessionsLeftToExtract = checkExtractionProgress(extractionLog, params.extrctItms.EXT.sessionsToExtract, "Extract_slrt");    
    % extractEXT_SLRT(params, params.extrctItms.EXT.sessionsToExtract, params.extrctItms.EXT.extrctModules.SLRT.Q);

    sessions = params.extrctItms.EXT.sessionsToExtract.sessions;
    numSessions = size(sessions,1);
    for i = 1:numSessions
        session = sessions{i};
        slrtFile = fullfile(params.paths.Data.RAW.SLRT.cloud,session);
        SLRT = extractEXT_SLRT(slrtFile);
        imecPath = fullfile(params.paths.Data.RAW.NPXLS.cloud,session,sprintf("%s_imec0",session));
        imecDir = dir(imecPath);        
        sortedTrigs = struct2table(imecDir);
        sortedTrigs = sortedTrigs.name;
        sortedTrigs = sortedTrigs(contains(sortedTrigs,"sorted"));
        numTrigs = size(sortedTrigs,1);
        for j = 1:numTrigs              
            sortedFldr = sortedTrigs{i};
            kSortPath = fullfile(imecPath,sortedFldr,"kilosort4");
            lfpPath = fullfile(imecPath,sortedFldr);
            AP = extractEXT_AP(SLRT, kSortPath);
            LFP = extractEXT_LFP(SLRT, lfpPath);
        end
        extrctModules = params.extrctItms.EXT.extrctModules;
        extModNames = fieldnames(extrctModules);
        for j = 1:length(extModNames)
            extMod = extModNames{j};
            if exist(extMod)
                extModPath = fullfile(params.paths.Data.EXT.(extMod).cloud,sprintf("%s.mat",session));
                save(extModPath,extMod);
            end
        end
    end
   
    % Final mark of completed extraction for ext layer
    extractionLog = readtable(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","EXT")));
    extractionLog(contains(extractionLog.SessionName,(params.extrctItms.EXT.sessionsToExtract.sessions)),:).Extracted = ones(height(params.extrctItms.EXT.sessionsToExtract.sessions),1);       
    writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","EXT")));


end