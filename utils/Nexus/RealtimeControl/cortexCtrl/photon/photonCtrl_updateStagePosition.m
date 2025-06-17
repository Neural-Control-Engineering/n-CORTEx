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
            stagePositionSelection = "";
            idx_stagePositionSelection = 1; 
            subjectFolderPath = fullfile(nexObj.nCORTEx.params.paths.expmntPath_cloud,"Subjects/",nexObj.nCORTEx.params.subject);
            filePath_spf = fullfile(subjectFolderPath,"photon","stagePositions.xy");
            
        case "hover"
            stagePositionSelection = "";
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
    %% SAFETY 
    if contains(stagePositionSelection,"Rig") || contains(stagePositionSelection,"rig")
        warningPrompt ="WARNING: Load rig type maneuver detected, please ensure objective is not mounted! Do you wish to proceed?";
        userin = questdlg(warningPrompt,"WARNING!","No","Yes","No");
        switch userin
            case "No"
                return
            case ''
                return           
        end
    end
    %% ACTUATE
    photonCtrl_moveToPos(prxObj_photon,idx_stagePositionSelection,filePath_spf);
    controlPanel = prxObj_photon.controlPanel;                
    %% ENABLE NEXT
    switch operation
        case "load"
            controlPanel.Figure.updatePositionButton_subject_over.Enable="on";
            controlPanel.Figure.resetPositionButton_subject.Enable="on";
        case "hover"
            controlPanel.Figure.updatePositionButton_subject_hover.Enable="on";
        case "over"
            controlPanel.Figure.updatePositionButton_subject_image.Enable="on";
        case "image"
    end
end