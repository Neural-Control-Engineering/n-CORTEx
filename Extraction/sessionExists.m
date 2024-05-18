function isExist = sessionExists(params, session, modality, layer)    
    disp(session);
    modSessions_local = struct2table(dir(fullfile(params.paths.Data.(layer).(modality).local)));
    modSessions_cloud = struct2table(dir(fullfile(params.paths.Data.(layer).(modality).cloud)));
    modSessions = [modSessions_local.name; modSessions_cloud.name];
    isExist = any(contains(modSessions, session));
end