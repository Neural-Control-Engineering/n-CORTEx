function isExist = sessionExists(params, session, modality)    
    modSessions_local = struct2table(dir(fullfile(params.paths.rawData.(modality).local)));
    modSessions_cloud = struct2table(dir(fullfile(params.paths.rawData.(modality).cloud)));
    modSessions = [modSessions_local.name; modSessions_cloud.name]
    isExist = any(contains(modSessions, session));
end