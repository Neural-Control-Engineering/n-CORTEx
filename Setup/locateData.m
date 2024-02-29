function params = locateData(params, modalities)
    modalityDirs_local = categorize(fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Data","RAW"),'isDir');
    modalityDirs_cloud = categorize(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","RAW"),'isDir');
    for i = 1:length(modalities)
        modality = modalities{i};
        modalityDir_local = modalityDirs_local(contains(cellstr(modalityDirs_local),modality));
        modalityDir_cloud = modalityDirs_cloud(contains(cellstr(modalityDirs_cloud),modality));
        if ~isempty(modalityDir_local)
            params.paths.Data.RAW.(modality).local = fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Data","RAW",string(modalityDir_local));
        else
            params.paths.Data.RAW.(modality).local = [];
        end

        if ~isempty(modalityDir_cloud)
            params.paths.Data.RAW.(modality).cloud = fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","RAW",string(modalityDir_cloud));
        else
            params.paths.Data.RAW.(modality).cloud = [];
        end        
    end
end