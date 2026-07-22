function repair_ncortexCache(params)
    % load pre-existing cache and use a cache entry to synthesize a new cache for
    % headless sessions
    % fld = uigetdir(params.paths.projDir_local);
    [fld] = uigetdir(params.paths.projDir_local);
    % if isSingle
    %     pDir = struct2table(dir(fld));
    %     sessionDir = ((pDir.folder(1,1)));
    %     sessionDir = dir(sessionDir{1})
    %     sessionDir = struct2table(dir(parentFid))
    % else
    %     sessionDir = struct2table(dir(fld));
    % end
    % 
    sessionDir = struct2table(dir(fld));
    % load cache
    path_cache = fullfile(params.paths.nCORTEx_repo,"Setup","nCORTExCache.mat");
    load(path_cache)
    % access cache
    hostName = getHostName;    
    sessionCache = cache.(hostName).sessionCache;
    % upgrade later
    cache_sim = cache.(hostName).sessionCache(end,:);
    % for each un-cached session
    for i = 3:length(sessionDir.name)
        sessionName = convertCharsToStrings(sessionDir.name(i));
        dataDir = cache_sim.DataDir;
        dataDir.params.sessionLabel=convertStringsToChars(sessionName);
        try
            dataDir.params.spinParams.sessionLabel=convertStringsToChars(sessionName);
        catch e
            disp(getReport(e));
        end
        newCache = table(sessionName,dataDir,'VariableNames',{'SessionName','DataDir'});
        % append
        sessionCache = [sessionCache; newCache];
    end
    cache.(hostName).sessionCache=sessionCache;
    % save cache
    save(path_cache,"cache")
end