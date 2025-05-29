function photonCtrl_updateStagePosition(nexObj, operation)
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    % get selected position and index
    switch operation
        case "load"
            stagePositionSelection = nexObj.Figure.selectPositionDropDown.Value;
            idx_stagePositionSelection = nexObj.nCORTEx.params.expmntCfg_target.targets.photon.stagePositions.(stagePositionSelection).index;    
            expmntModulePath = fullfile(nexObj.nCORTEx.params.paths.experimentModules,nexObj.nCORTEx.params.experiment);
            filePath_spf = fullfile(expmntModulePath,"photon","stagePositions.xy");
        case "over"            
            idx_stagePositionSelection = 1; 
            subjectFolderPath = fullfile(nexObj.nCORTEx.params.paths.expmntPath_cloud,"Subjects/",nexObj.nCORTEx.params.subject);
            filePath_spf = fullfile(subjectFolderPath,"photon","stagePositions.xy");
        case "hover"
            idx_stagePositionSelection = 2;            
            subjectFolderPath = fullfile(nexObj.nCORTEx.params.paths.expmntPath_cloud,"Subjects/",nexObj.nCORTEx.params.subject);
            filePath_spf = fullfile(subjectFolderPath,"photon","stagePositions.xy");
        case "image"
            stagePositionSelection = nexObj.Figure.selectPositionDropDown_subject.Value;
            idx_stagePositionSelection = nexObj.nCORTEx.params.subjectCfg.targets.photon.stagePositions.(stagePositionSelection).index;    
            subjectFolderPath = fullfile(nexObj.nCORTEx.params.paths.expmntPath_cloud,"Subjects/",nexObj.nCORTEx.params.subject);
            filePath_spf = fullfile(subjectFolderPath,"photon","stagePositions.xy");
    end
    % stagePositionSelection = nexObj.Figure.selectPositionDropDown.Value;
    % idx_stagePositionSelection = nexObj.nCORTEx.params.expmntCfg_target.targets.photon.stagePositions.(stagePositionSelection).index;    
    % % load experiment-specific stage position file
    % expmntModulePath = fullfile(nexObj.nCORTEx.params.paths.experimentModules,nexObj.nCORTEx.params.experiment);
    % filePath_spf = fullfile(expmntModulePath,"stagePositions.xy");
    % prxObj_photon.Server.SendScriptCommands(sprintf("-lspf %s",filePath_spf));
    % % move to stage position
    photonCtrl_moveToPos(prxObj_photon,idx_stagePositionSelection,filePath_spf);
end