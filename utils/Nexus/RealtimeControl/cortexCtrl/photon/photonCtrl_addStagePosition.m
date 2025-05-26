function photonCtrl_addStagePosition(nexObj)
    % user-dialog for name
    prompt = {'Enter position name:'};    
    dlgtitle = 'New Stage Position';
    answer = inputdlg(prompt,dlgtitle);
    positionName = answer{1};
    % framework handling
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    % load stage position file    
    filePath_spf = fullfile(nexObj.nCORTEx.params.paths.repo)
    prxObj_photon.Server.SendScriptCommands(sprintf("lspf",filePath_spf))
    % add to stage position file
    % save stage position file
    % write to expmntCfg (and save expmntCfg)
    % update dropdown items
    

end