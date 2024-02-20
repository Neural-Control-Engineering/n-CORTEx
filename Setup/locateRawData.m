function params = locateRawData(params, extractList)
    modalityDirs_local = categorize(fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Data","Raw-Data"),'isDir');
    modalityDirs_cloud = categorize(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","Raw-Data"),'isDir');
    for i = 1:length(extractList)
        modality = extractList{i};
        modalityDir_local = modalityDirs_local(contains(cellstr(modalityDirs_local),modality));
        modalityDir_cloud = modalityDirs_cloud(contains(cellstr(modalityDirs_cloud),modality));
        if ~isempty(modalityDir_local)
            params.paths.rawData.(modality).local = fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Data","Raw-Data",string(modalityDir_local));
        else
            params.paths.rawData.(modality).local = [];
        end

        if ~isempty(modalityDir_cloud)
            params.paths.rawData.(modality).cloud = fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","Raw-Data",string(modalityDir_cloud));
        else
            params.paths.rawData.(modality).cloud = [];
        end        
    end
end