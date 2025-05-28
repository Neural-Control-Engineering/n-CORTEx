function photonCtrl_addStagePosition(nexObj)
    % user-dialog for name
    prompt = {'Enter position name:'};    
    dlgtitle = 'New Stage Position';
    answer = inputdlg(prompt,dlgtitle);
    positionName = answer{1};
    % framework handling
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    % load stage position file    
    expmntModulePath = fullfile(nexObj.nCORTEx.params.paths.experimentModules,nexObj.nCORTEx.params.experiment);
    filePath_spf = fullfile(expmntModulePath,"stagePositions.xy");
    prxObj_photon.Server.SendScriptCommands(sprintf("-lspf %s",filePath_spf));
    % add to stage position file
    prxObj_photon.Server.SendScriptCommands(sprintf("-spa"));
    % save stage position file
    prxObj_photon.Server.SendScriptCommands(sprintf("-sspf %s",filePath_spf));
    % read position file as table
    spt = pv_readSPF(filePath_spf);
    idx_newStagePos = spt{end,"index"}+1;
    % write to expmntCfg (and save expmntCfg)
    nexObj.nCORTEx.params.expmntCfg_target.targets.photon.stagePositions.(positionName).index = idx_newStagePos;
    expmntCfg_target = nexObj.nCORTEx.params.expmntCfg_target;
    save(fullfile(expmntModulePath,"expmntCfg_target.mat"),"expmntCfg_target");
    % update dropdown items
    list_newStagePositions = [nexObj.Figure.selectPositionDropDown.Items, positionName];
    nexObj.Figure.selectPositionDropDown.Items = list_newStagePositions;
end