function params = locateData(params)
    extrctLayers = string(categorize(fullfile(params.paths.projDir_cloud,"Experiments",params.experiment,"Data"),'isDir'));
    if isempty(extrctLayers)
        extrctLayers = string(categorize(fullfile(params.paths.projDir_local,"Experiments",params.experiment,"Data"),'isDir'));
    end
    for j = 1:length(extrctLayers)
        layer = extrctLayers(j);
        modalityDirs_local = string(categorize(fullfile(params.paths.projDir_local,"Experiments",params.experiment,"Data",layer),'isDir'));
        modalityDirs_cloud = string(categorize(fullfile(params.paths.projDir_cloud,"Experiments",params.experiment,"Data",layer),'isDir'));
        params.paths.Data.(layer).local = fullfile(params.paths.projDir_local,"Experiments",params.experiment,"Data",layer);
        params.paths.Data.(layer).cloud = fullfile(params.paths.projDir_cloud,"Experiments",params.experiment,"Data",layer);
        % if isempty(modalityDirs_local) && isempty(modalityDirs_cloud)
        %     params.paths.Data.(layer).local = fullfile(params.paths.projDir_local,"Experiments",params.experiment,"Data",layer);
        %     params.paths.Data.(layer).cloud = fullfile(params.paths.projDir_cloud,"Experiments",params.experiment,"Data",layer);
        % else
        if isempty(modalityDirs_cloud)
            modalityDirs = modalityDirs_local;
            projDir_ref = params.paths.projDir_local;
        else
            modalityDirs = modalityDirs_cloud;
            projDir_ref = params.paths.projDir_cloud;
        end
        if ~isempty(modalityDirs) 
            for i = 1:length(modalityDirs)
                modality = modalityDirs(i);
                % if isfolder(fullfile(params.paths.projDir_cloud,"Experiments",params.experiment,"Data",layer,modality))
                if isfolder(fullfile(projDir_ref,"Experiments",params.experiment,"Data",layer,modality))
                    modalityDir_local = modalityDirs_local(contains(cellstr(modalityDirs_local),modality));
                    modalityDir_cloud = modalityDirs_cloud(contains(cellstr(modalityDirs_cloud),modality));
                    if ~isempty(modalityDir_local)
                        params.paths.Data.(layer).(modality).local = fullfile(params.paths.projDir_local,"Experiments",params.experiment,"Data",layer,string(modalityDir_local));
                    else
                        params.paths.Data.(layer).(modality).local = [];
                    end    
                    if ~isempty(modalityDir_cloud)
                        params.paths.Data.(layer).(modality).cloud = fullfile(params.paths.projDir_cloud,"Experiments",params.experiment,"Data",layer,string(modalityDir_cloud));
                    else
                        params.paths.Data.(layer).(modality).cloud = [];
                    end        
                end
            end
        end
    end

    % If the user previously ran locateDTS, their explicit path overrides the scan.
    if isfield(params.paths,"repo_path")
        cacheFile = fullfile(params.paths.repo_path, 'Setup', 'nCORTExCache.mat');
    elseif isfield(params.paths,"nCORTEx_repo")
        cacheFile = fullfile(params.paths.nCORTEx_repo, 'Setup', 'nCORTExCache.mat');
    end
    if isfile(cacheFile)
        load(cacheFile, 'cache');
        hn = getHostName();
        if isfield(cache, hn) && isfield(cache.(hn), 'dtsPath') && ...
                ~isempty(cache.(hn).dtsPath)
            params.paths.Data.DTS.local = cache.(hn).dtsPath;
        end
    end
end