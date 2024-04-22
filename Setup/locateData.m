function params = locateData(params)
    extrctLayers = string(categorize(fullfile(params.paths.projDir_cloud,"Experiments",params.experiment,"Data"),'isDir'));
    for j = 1:length(extrctLayers)
        layer = extrctLayers(j);
        modalityDirs_local = string(categorize(fullfile(params.paths.projDir_local,"Experiments",params.experiment,"Data",layer),'isDir'));
        modalityDirs_cloud = string(categorize(fullfile(params.paths.projDir_cloud,"Experiments",params.experiment,"Data",layer),'isDir'));
        for i = 1:length(modalityDirs_cloud)
            modality = modalityDirs_cloud(i);
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