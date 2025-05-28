function photonCtrl_updateStagePosition(nexObj)
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    % get selected position and index
    stagePositionSelection = nexObj.Figure.selectPositionDropDown.Value;
    idx_stagePositionSelection = nexObj.nCORTEx.params.expmntCfg_target.targets.photon.stagePositions.(stagePositionSelection).index;    
    % % load experiment-specific stage position file
    expmntModulePath = fullfile(nexObj.nCORTEx.params.paths.experimentModules,nexObj.nCORTEx.params.experiment);
    filePath_spf = fullfile(expmntModulePath,"stagePositions.xy");
    % prxObj_photon.Server.SendScriptCommands(sprintf("-lspf %s",filePath_spf));
    % % move to stage position
    photonCtrl_moveToPos(prxObj_photon,idx_stagePositionSelection,filePath_spf);
end