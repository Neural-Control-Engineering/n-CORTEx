function extractEXT(params)
    % process each experiment associated modality for given list of
    % sessions
    extrctModules = params.extrctItms.EXT.extrctModules;
    extrctFields = fieldnames(extrctModules);
    extractionLog = params.extrctItms.EXT.extractionLog;    
    % process datastreams relative to SLRT
    try
        load(fullfile(params.paths.expmntPath_cloud,"extractCfg.mat"),"extractCfg");
    catch
        extractCfg = struct;
        extractCfg.EXT = struct;
        disp("extractCfg file not found, proceeding...");
    end
    % extractEXT_SLRT(params, params.extrctItms.EXT.sessionsToExtract, params.extrctItms.EXT.extrctModules.SLRT.Q);

    sessions = params.extrctItms.EXT.sessionsToExtract.sessions;
    switch params.extractCfg.experiment
        case 'JOLT_legacy'
            sessionsLeftToExtract = checkExtractionProgress(extractionLog, params.extrctItms.EXT.sessionsToExtract, "Extract_slrt");    
            Q = params.extrctItms.EXT.Q;
            params.extractCfg.EXT = extractCfg.EXT;
            extractJOLT(params, sessionsLeftToExtract, Q);
        otherwise
            numSessions = size(sessions,1);
            for i = 1:numSessions
                session = sessions{i};
                slrtFile = fullfile(params.paths.Data.RAW.SLRT.cloud,session);
                SLRT = extractEXT_SLRT(slrtFile);
                % BOOST FCN
                if isfield(extractCfg.EXT,"SLRT")
                    try % signle boostFcn case
                        args = extractCfg.EXT.SLRT.args;
                        SLRT = extractCfg.EXT.SLRT.boostFcn(params, SLRT , args);
                    catch e
                        % disp("WARNING: boostFcn for SLRT failed \n")
                        % disp(e);
                        try  % accomodate multiple Fcns in cell array format                            
                            for j = 1:size(extractCfg.EXT.SLRT.boostFcn,1)
                                boostFcn = extractCfg.EXT.SLRT.boostFcn{j};
                                args = extractCfg.EXT.SLRT.args{j};
                                SLRT = boostFcn(params, SLRT, args);
                            end
                        catch e
                            disp(e);
                        end
                    end
                end
                % SAVE SLRT
                extModPath = fullfile(params.paths.Data.EXT.SLRT.cloud,sprintf("%s.mat",session));
                save(extModPath, "SLRT");
                % EXTRACT ADDITIONAL MODALITIES
                extrctModules = params.extrctItms.EXT.extrctModules;
                extModNames = fieldnames(extrctModules);
                extData = struct;
                for j = 1:length(extModNames)
                    extMod = extModNames{j};
                    % extrctHndl = str2func(sprintf("extractEXT_%s", extrctModule));                        
                    extrctHndl = str2func(sprintf("extractEXT_%s", extMod));                        
                    try
                        extData.(extMod) = extrctHndl(SLRT, params.paths.Data);
                        % BOOST FCN
                        if isfield(extractCfg.EXT,(extMod))
                            try
                                args = extractCfg.EXT.(extMod).args;
                                extData.(extMod) = extractCfg.EXT.(extMod).boostFcn(params, extData.(extMod) , args);
                            catch e
                                fprintf("WARNING: boostFcn for %s failed \n",extMod)
                                disp(e);
                            end
                        end
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