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
    % Registry
    nexInit_registry(nexon);
    % router Panel   
    
    % nexon.UserData.npxls.shanks.shank1 = npxls_shank(nexon);
    % nexPlot_npxls_LFP(nexon);    
    % nexPlot_npxls_PSD(nexon);
    %% OPTIONAL
    % PSD_trial = grabDataFrame(nexon,"PSD_cwt");
    % f_psd = grabDataFrame(nexon,"f_cwt");
    % t_psd = grabDataFrame(nexon,"t_cwt");
    % nexon.console.NPXLS.shanks.shank1.scope.spectroGram1 = nexObj_spectroGram(nexon, nexon.console.NPXLS.shanks.shank1,PSD_trial,"PSD_cwt",f_psd, t_psd);
    % ACTIVATE PYENV
    try
        pyVersion = "/home/user/miniconda3/envs/nexus/bin/python";
        pyenv(Version=pyVersion,ExecutionMode="OutOfProcess");    
    catch e
        disp(getReport(e));
    end
    % ADD NCORTEX TO PYTHON PATH
    % % Specify the directory where the Python module is located
    % module_dir = pwd;
    % 
    % % Add the directory to Python’s sys.path
    % if count(py.sys.path, module_dir) == 0
    %     insert(py.sys.path, int32(0), module_dir);
    % end
    % site_packages_path = 'C:\path\to\your\venv\Lib\site-packages'; % Update with the actual path
    site_packages_path="~/miniconda3/envs/nexus/lib/python3.10/site-packages";
    if count(py.sys.path, site_packages_path) == 0
        insert(py.sys.path, int32(0), site_packages_path);
    end
end