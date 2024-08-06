function mergeExpmntDirs(paths, expmnt)
    projDir_cloud = paths.projDir_cloud;
    projDir_local = paths.projDir_local;
    % 1 : generate cloudDir (if doesn't exist)
    expmntPath = fullfile(projDir_cloud,"Experiments",expmnt);
    if ~isfolder(expmntPath)
        % if cloud expmntPath doesnt exist, build new
        modalityList_RAW = convertCharsToStrings(fieldnames(paths.Data.RAW));
        modalityList_RAW = modalityList_RAW(~(strcmp(modalityList_RAW,"local") | strcmp(modalityList_RAW,"cloud")));
        extLayers = convertCharsToStrings(fieldnames(paths.Data));
        buildExperimentDirectory(expmntPath, modalityList_RAW, extLayers);
    end    

    % 2 : merge extractionLogs
    extLogDir_cloud = fullfile(projDir_cloud,"Experiments",expmnt,"Extraction-Logs");
    extLogDir_local = fullfile(projDir_local,"Experiments",expmnt,"Extraction-Logs");
    mergeExtractionLogs(paths, expmnt, extLogDir_local, extLogDir_cloud);

    % 3 : merge subjectDirs
    expDir_cloud = fullfile(projDir_cloud,"Experiments",expmnt);
    expDir_local = fullfile(projDir_local,"Experiments",expmnt);
    mergeSubjectDirs(expDir_local, expDir_cloud);

end