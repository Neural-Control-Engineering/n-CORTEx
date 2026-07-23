function repairCache(nCORTEx)
    % Search Local directory for stray sessions
    projDir_local = nCORTEx.params.paths.projDir_local;
    projDir_cloud = nCORTEx.params.paths.projDir_cloud;
    experiment = nCORTEx.params.experiment;
    path_rawSLRT = fullfile(projDir_local,"Experiments/",experiment,"Data","RAW","SLRT");
    path_rawSLRT_cloud = fullfile(projDir_cloud,"Experiments/",experiment,"Data","RAW","SLRT");
    dir_rawSLRT = dir(path_rawSLRT);
    dir_rawSLRT_cloud = dir(path_rawSLRT_cloud);
    sessions_rawSLRT = struct2table(dir_rawSLRT).name;
    sessions_rawSLRT = cellfun(@(s) strrep(s,".mat",""),sessions_rawSLRT, "UniformOutput",true);
    sessions_rawSLRT_cloud = struct2table(dir_rawSLRT_cloud).name;
    sessions_rawSLRT_cloud = cellfun(@(s) strrep(s,".mat",""),sessions_rawSLRT_cloud, "UniformOutput",true);
    % cross reference with RAW extraction log and existing session cache to index un-cached sessions
    % load cache
    path_cache = fullfile(nCORTEx.params.paths.nCORTEx_repo,"Setup","nCORTExCache.mat");
    load(path_cache);
    sessions_cache = cache.(nCORTEx.params.hostName).sessionCache.SessionName;
    % load extraction log
    extractionLog = readtable(fullfile(nCORTEx.params.paths.projDir_cloud,"Experiments",nCORTEx.params.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","RAW")));
    sessions_rawLog = convertCharsToStrings(extractionLog.SessionName);
    % find un-cached sessions (RULE: EXISTS IN RAWDIR_local, DOESNT EXIST
    % IN CACHE AND DOESNT EXIST IN CLOUD (DEDUP))
    [inCloud, idx_inCloud] = ismember(sessions_rawSLRT, sessions_rawSLRT_cloud);
    [inCache, idx_inCache] = ismember(sessions_rawSLRT, sessions_cache);
    isUnCached = (~inCloud) & (~inCache); % sessions that arent in the CACHE and HAVENT already been uploaded
    sessions_unCached = sessions_rawSLRT(isUnCached);
    newCache = [];
    for i = 1:length(sessions_unCached)
        % retrieve metaparameters
        session = sessions_unCached(i);
        fprintf("Repairing %s \n",session);        
        sessionPath = fullfile(path_rawSLRT,sprintf("%s.mat",session));
        if isfile(sessionPath)
            load(sessionPath);
            dataDir.directory = realtimeLog.metadata.paths.Data.RAW;
            dataDir.params = realtimeLog.metadata;
            newCacheRow.SessionName = session;
            newCacheRow.DataDir = dataDir;
            newCacheRow_table = struct2table(newCacheRow);
            newCache = [newCache; newCacheRow_table];
            if ~isfield(realtimeLog.metadata,"TrialMask")
                TrialMask='0-';
            else
                TrialMask = realtimeLog.metadata.TrialMask;
            end
            Extracted=0;
            SessionName=session;
            extractionRow = table(SessionName,Extracted,TrialMask);
            % IF NOT CURRENTLY IN EXTRACTION LOG
            sessionInLog = ismember(session,sessions_rawLog);
            if ~sessionInLog
                disp("Logging Session");
                expmntPath = fullfile(realtimeLog.metadata.paths.projDir_cloud,"Experiments",experiment);
                log4Extraction(expmntPath,extractionRow,'csv');
            end
        end        
    end
    % append new cache items
    cacheTable = cache.(nCORTEx.params.hostName).sessionCache;
    cacheTable = [cacheTable; newCache];
    cache.(nCORTEx.params.hostName).sessionCache = cacheTable;
    % surgical replace into cache and resave
    save(path_cache,"cache");    
    disp("CACHE REPAIRED");
end
