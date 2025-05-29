function photonCtrl_addStagePosition(nexObj, operation)
    % user-dialog for name
    prompt = {'Enter position name:'};    
    dlgtitle = 'New Stage Position';
    answer = inputdlg(prompt,dlgtitle);
    positionName = answer{1};
    % framework handling
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    % load stage position file    
    switch operation
        case "load"
            selectPositionDropDownUIField = "selectPositionDropDown";
            cfgPath = fullfile(nexObj.nCORTEx.params.paths.experimentModules,nexObj.nCORTEx.params.experiment);
            spfPath = fullfile(cfgPath,"photon");                        
            cfgField = "experimentCfg_target";
        case "image"
            selectPositionDropDownUIField = "selectPositionDropDown_subject";
            cfgPath = fullfile(nexObj.nCORTEx.params.paths.projDir_cloud,"Experiments",nexObj.nCORTEx.params.experiment,"Subjects",nexObj.nCORTEx.params.subject);
            spfPath = fullfile(cfgPath,"photon");
            cfgField = "subjectCfg";
    end
    % initialize
    filePath_spf = fullfile(spfPath,"stagePositions.xy");
    prxObj_photon.Server.SendScriptCommands('-spc');
    prxObj_photon.Server.SendScriptCommands(sprintf("-lspf %s",filePath_spf));
    % add to stage position file
    prxObj_photon.Server.SendScriptCommands(sprintf("-spa"));
    % save stage position file
    prxObj_photon.Server.SendScriptCommands(sprintf("-sspf %s",filePath_spf));
    % read position file as table
    spt = pv_readSPF(filePath_spf);
    idx_newStagePos = spt{end,"index"}+1;
    % write to expmntCfg (and save expmntCfg)
    % nexObj.nCORTEx.params.expmntCfg_target.targets.photon.stagePositions.(positionName).index = idx_newStagePos;
    nexObj.nCORTEx.params.(cfgField).targets.photon.stagePositions.(positionName).index = idx_newStagePos;
    cfgSave.(cfgField) = nexObj.nCORTEx.params.(cfgField);
    save(fullfile(cfgPath,sprintf("%s.mat",cfgField)),"-struct","cfgSave");
    % update dropdown items
    list_newStagePositions = [nexObj.Figure.(selectPositionDropDownUIField).Items, positionName];
    nexObj.Figure.(selectPositionDropDownUIField).Items = list_newStagePositions;
end