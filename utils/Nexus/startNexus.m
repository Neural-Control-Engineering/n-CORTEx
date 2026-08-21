 function nexon = startNexus(params, DTS)    
    nexon = Nexon();
    % COLOR SETTINGS
    nexon.settings.Colors.cyberGreen   = [0.24, 0.94, 0.46];
    nexon.settings.Colors.vyberGreen = [0, 1, 0.48];
    nexon.settings.Colors.cyberRed     = [1.00, 0.33, 0.42];
    nexon.settings.Colors.cyberBlack   = [0.00, 0.00, 0.00];
    nexon.settings.Colors.disableGreen = [0.05, 0.14, 0.08];
    nexon.settings.Colors.cyberOrange  = [1.00, 0.41, 0.16];
    nexon.settings.Colors.cyberGrey    = [0.18, 0.18, 0.22];
    nexon.settings.Colors.activeGrey   = [0.96, 0.96, 0.96];
    nexon.settings.Colors.disableGrey  = [0.50, 0.50, 0.50];
    nexon.settings.Colors.enableWhite  = [1.00, 1.00, 1.00];
    nexon.settings.Colors.cyberPink = [1, 9, 0.5176];
    % nexon.console.base = uifigure("Position",[25,1260,1000, 600],"Color",[0,0,0]);
    % nexon.console.base.UserData.DTS = DTS;
    % nexon.console.base.UserData.params = params;    
    nexon.console.BASE = nexPanel_BASE(nexon, DTS, params);     
    if ~isempty(DTS)
        signal_types = dtsIO_readTF(nexon,'signal_types',[]);
        nexon.console.BASE.controlPanel = nexObj_controlPanel(nexon);    
        try
            nexon.console.BASE.router.UserData.subjectDir = fullfile(params.paths.nCORTEx_local,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subject);        
            nexon.console.BASE.router.UserData.subjectDir_cloud = fullfile(params.paths.nCORTEx_cloud,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subject);        
        catch
            nexon.console.BASE.router.UserData.subjectDir = fullfile(params.paths.nCORTEx_local,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subj);        
            nexon.console.BASE.router.UserData.subjectDir_cloud = fullfile(params.paths.nCORTEx_cloud,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subj);        
        end
        try
            nexon.console.NPXLS = nexPanel_NPXLS(nexon, 1);
        catch e
            disp(getReport(e));
            disp("UNABLE TO GENERATE NPXLS PANEL")
        end
        try
            nexon.console.SLRT = nexPanel_SLRT(nexon);
        catch e
            disp(getReport(e));
            disp("UNABLE TO GENERATE SLRT PANEL")
        end
        % Auto-load nexTract manifest patches so derived dfColumns written in any
        % session are available immediately on startup.
        try
            if ~isempty(DTS) && ismember('h5_path', nexon.console.BASE.DTS.Properties.VariableNames)
                dtsIO_loadManifestPatches(nexon);
            end
        catch
        end
        try
            nexPanel_launcher(nexon);
        catch e
            disp(getReport(e));
            disp("UNABLE TO GENERATE LAUNCHER PANEL")
        end
    end

    % temporary patch for prebuffer length
    nexon.console.BASE.UserData.preBuffLen=3.5;


    % Registry — load from experiment-scoped cache; build + cache on first run.
    % On a cache hit, reconcile against the current DTS so newly added subjects /
    % categories appear (existing colors + region maps are preserved), then
    % re-cache the reconciled registry.
    if isfile(nexon.nexCachePath('registry'))
        nexon.loadRegistry();
        nexOp_mergeRegistry(nexon);
        nexon.saveRegistry();
    else
        nexInit_registry(nexon);
        nexon.saveRegistry();
    end
    % router Panel   
    
    % ACTIVATE PYENV
    if ispc
        homeDir           = getenv("USERPROFILE");
        pyVersion         = fullfile(homeDir, "miniconda3", "envs", "nexus", "python.exe");
        site_packages_path = fullfile(homeDir, "miniconda3", "envs", "nexus", "Lib", "site-packages");
    else
        homeDir           = getenv("HOME");
        pyVersion         = fullfile(homeDir, "miniconda3", "envs", "nexus", "bin", "python");
        site_packages_path = fullfile(homeDir, "miniconda3", "envs", "nexus", "lib", "python3.10", "site-packages");
    end
    try
        pyenv(Version=pyVersion,ExecutionMode="OutOfProcess");
    catch e
        disp(getReport(e));
    end

    if count(py.sys.path, site_packages_path) == 0
        insert(py.sys.path, int32(0), site_packages_path);
    end

    % Auto-launch configured figures for this host (panelStartup hook).
    try
        nexLaunch_auto(nexon, "panelStartup");
    catch e
        disp(getReport(e));
    end
end