function nex_panelStartup(nexon)
    params = nexon.console.BASE.params;
    if ~isempty(nexon.console.BASE.DTS)
        nexon.console.BASE.controlPanel = nexObj_controlPanel(nexon);            
        try
            nexon.console.BASE.router.UserData.subjectDir = fullfile(params.paths.nCORTEx_local,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subject);        
            nexon.console.BASE.router.UserData.subjectDir_cloud = fullfile(params.paths.nCORTEx_cloud,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subject);        
        catch
            nexon.console.BASE.router.UserData.subjectDir = fullfile(params.paths.nCORTEx_local,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subj);        
            nexon.console.BASE.router.UserData.subjectDir_cloud = fullfile(params.paths.nCORTEx_cloud,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subj);        
        end        
        nexon.console.NPXLS = nexPanel_NPXLS(nexon, 1);
        nexon.console.SLRT = nexPanel_SLRT(nexon);
    end
end