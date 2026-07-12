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
        % The NPXLS/SLRT analysis console is best-effort: it assumes an offline
        % DTS (probe-grid LFP, a signal_types column, ...) and throws on the
        % minimal DTS an ad-hoc capture produces. Its construction is secondary UI
        % — the DTS is already committed in appendToDTS — so a panel failure must
        % NOT propagate into the data write (which would abort stopCapture and lose
        % the SPK store) nor block the auto-launch. Guard each independently.
        try
            nexon.console.NPXLS = nexPanel_NPXLS(nexon, 1);
        catch e
            warning("nex_panelStartup:npxls", "NPXLS console skipped: %s", e.message);
        end
        try
            nexon.console.SLRT = nexPanel_SLRT(nexon);
        catch e
            warning("nex_panelStartup:slrt", "SLRT console skipped: %s", e.message);
        end
        % user special startup from this machine's factory settings
        nexLaunch_auto(nexon, "panelStartup");
    end
end