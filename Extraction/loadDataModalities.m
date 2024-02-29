function expmntData = loadDataModalities(params, session, expmntData, extrctModules, layer)
    % recurse in to check for subfolders, load
    extrctMods = fieldnames(extrctModules);
    for i = 1:length(extrctMods)
        extrctModule = extrctMods{i};
        if isfield(extrctModules.(extrctModule),'extrctModules')
            if ~isempty(extrctModules.(extrctModule).extrctModules)
                expmntData = loadDataModalities(params, session, expmntData, extrctModules.(extrctModule).extrctModules, layer);
            end
        end        
        loadFcnHndl = str2func(sprintf("load%s_%s",layer,extrctModule));
        if ~isempty(functions(loadFcnHndl).file)
            expmntData.(extrctModule) = loadFcnHndl(params, session);
        end
        
    end
end