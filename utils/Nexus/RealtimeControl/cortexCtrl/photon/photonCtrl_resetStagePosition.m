function photonCtrl_resetStagePosition(nexObj, operation)
    %% reset selected stage position save to current stage position
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    %% get selected position and index
    stagePositionSelection = nexObj.Figure.selectPositionDropDown.Value;
    idx_stagePositionSelection = nexObj.nCORTEx.params.expmntCfg_target.targets.photon.stagePositions.(stagePositionSelection).index;    
    % envFile = prxObj_photon.Server.SendScriptCommands("-le" envPath)
    filePath_env = fullfile(nexObj.nCORTEx.nCORTEx_repo,"Setup","photon","testEnv.env");
    prxObj_photon.Server.SendScriptCommands(sprintf("-le %s",filePath_env))
    stagePosition = prxObj_photon.Server.SendScriptCommands('-gts positionCurrent [XAxis [0]]')
    stagePosition = prxObj_photon.Server.SendScriptCommands('-gts "positionCurrent" ["XAxis" ["0"]]')
    stagePosition = prxObj_photon.Server.SendScriptCommands('-gts positionCurrent XAxis 0')
    [stagePosition, t] = prxObj_photon.Server.SendScriptCommands('-gmp Z')
    % stagePosition = prxObj_photon.Server.SendScriptCommands('-gts positionCurrent ["XAxis" ["0"]]')
    stagePosition = prxObj_photon.Server.SendScriptCommands("-gts motorStepSize XAxis")
    [a] = prxObj_photon.Server.SendScriptCommands("-gts positionCurrent YAxis 0")
    [a] = prxObj_photon.Server.SendScriptCommands("-gts positionCurrent ZAxis 0")
    %% load experiment-specific stage position file
    % expmntModulePath = fullfile(nexObj.nCORTEx.params.paths.experimentModules,nexObj.nCORTEx.params.experiment);
    % filePath_spf = fullfile(expmntModulePath,"stagePositions.xy");
    % % clear current positions
    prxObj_photon.Server.SendScriptCommands('-spc');
    %% load xy file 
    proxObj.Server.SendScriptCommands(sprintf('-lspf %s', filePath));
    spt = pv_readSPF(filePath_spf);
    pv_writeSPF(filePath,spt);
end