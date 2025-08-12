function photonCtrl_resetStagePosition(nexObj, operation)    
    %% reset selected stage position save to current stage position
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    % clear current pos
    prxObj_photon.Server.SendScriptCommands('-spc');
    %% get selected position and index
    switch operation
        case "load"
            selectPositionDropDownUIField = "selectPositionDropDown";
            cfgPath = fullfile(nexObj.nCORTEx.params.paths.experimentModules,nexObj.nCORTEx.params.experiment);
            spfPath = fullfile(cfgPath,"photon");                        
            cfgField = "expmntCfg_target";
        case "image"
            selectPositionDropDownUIField = "selectPositionDropDown_subject";
            cfgPath = fullfile(nexObj.nCORTEx.params.paths.projDir_cloud,"Experiments",nexObj.nCORTEx.params.experiment,"Subjects",nexObj.nCORTEx.params.subject);
            spfPath = fullfile(cfgPath,"photon");
            cfgField = "subjectCfg";
    end
    filePath_spf = fullfile(spfPath,"stagePositions.xy");
    stagePositionSelection = nexObj.Figure.(selectPositionDropDownUIField).Value;
    idx_stagePositionSelection = nexObj.nCORTEx.params.(cfgField).targets.photon.stagePositions.(stagePositionSelection).index;    
    % envFile = prxObj_photon.Server.SendScriptCommands("-le" envPath)
    % filePath_env = fullfile(nexObj.nCORTEx.nCORTEx_repo,"Setup","photon","testEnv.env");
    % prxObj_photon.Server.SendScriptCommands(sprintf("-le %s",filePath_env))
    % stagePosition = prxObj_photon.Server.SendScriptCommands('-gts positionCurrent [XAxis [0]]')
    % stagePosition = prxObj_photon.Server.SendScriptCommands('-gts "positionCurrent" ["XAxis" ["0"]]')
    % stagePosition = prxObj_photon.Server.SendScriptCommands('-gts positionCurrent XAxis 0')
    % [stagePosition, t] = prxObj_photon.Server.SendScriptCommands('-gmp Z')
    % % stagePosition = prxObj_photon.Server.SendScriptCommands('-gts positionCurrent ["XAxis" ["0"]]')
    % stagePosition = prxObj_photon.Server.SendScriptCommands("-gts motorStepSize XAxis")
    % [a] = prxObj_photon.Server.SendScriptCommands("-gts positionCurrent YAxis 0")
    % [a] = prxObj_photon.Server.SendScriptCommands("-gts positionCurrent ZAxis 0")
    %% get stage position coordinates
    % stagePosition_x = prxObj_photon.Server.GetState("positionCurrent","XAxis","0");
    % stagePosition_y = prxObj_photon.Server.GetState("positionCurrent","YAxis","0");
    % stagePosition_z = prxObj_photon.Server.GetState("positionCurrent","ZAxis","0");
    stagePosition_x = prxObj_photon.Server.GetMotorPosition("X");
    stagePosition_y = prxObj_photon.Server.GetMotorPosition("Y");
    stagePosition_z = prxObj_photon.Server.GetMotorPosition("Z");
    %% splice new coordinates
    % proxObj.Server.SendScriptCommands(sprintf('-lspf %s', filePath));
    spt = pv_readSPF(filePath_spf);
    % insert
    spt(idx_stagePositionSelection,:).x = (stagePosition_x);
    spt(idx_stagePositionSelection,:).y = (stagePosition_y);
    % position z special formatting
    zCell = spt(idx_stagePositionSelection,:).z;
    % zCell_split = split(zCell,",");
    % zCell_split{1} = num2str(stagePosition_z);
    % zCell_new = join(zCell_split,",");
    zCell_new = pv_updateZCell(zCell,stagePosition_z);
    spt(idx_stagePositionSelection,:).z = zCell_new;
    %% conditional: refPlane update
    % update index 0:1 planes relative to refPlane
    if strcmp(stagePositionSelection,"refPlane")
        ref_x = stagePosition_x;
        ref_y = stagePosition_y;
        ref_z = stagePosition_z;
        overOffset = 5000;
        hoverOffset = 2000;
        zCell_over = pv_updateZCell(zCell,ref_z-overOffset);
        zCell_hover = pv_updateZCell(zCell,ref_z-hoverOffset);
        % idx 1 - over
        spt(1,:).x = ref_x;
        spt(1,:).y = ref_y;
        spt(1,:).z = zCell_over;
        % idx 2 - hover
        spt(2,:).x = ref_x;
        spt(2,:).y = ref_y;
        spt(2,:).z = zCell_hover;
    end
    % write back to file
    pv_writeSPF(filePath_spf,spt);
end