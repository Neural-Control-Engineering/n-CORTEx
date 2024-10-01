function nexon = startNexus(params, DTS)
    nexon = Nexon();
    nexon.settings.Colors.cyberGreen=[0.24,0.94,0.46];
    % nexon.console.base = uifigure("Position",[25,1260,1000, 600],"Color",[0,0,0]);
    % nexon.console.base.UserData.DTS = DTS;
    % nexon.console.base.UserData.params = params;    
    nexon.console.BASE = nexPanel_BASE(nexon, DTS, params);     
    nexon.console.BASE.router.UserData.subjectDir = fullfile(params.paths.nCORTEx_local,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subject);        
    % router Panel   
    nexon.console.NPXLS = nexPanel_NPXLS(nexon, 1);
    % nexon.UserData.npxls.shanks.shank1 = npxls_shank(nexon);
    % nexPlot_npxls_LFP(nexon);    
    % nexPlot_npxls_PSD(nexon);
    %% OPTIONAL
    % PSD_trial = grabDataFrame(nexon,"PSD_cwt");
    % f_psd = grabDataFrame(nexon,"f_cwt");
    % t_psd = grabDataFrame(nexon,"t_cwt");
    % nexon.console.NPXLS.shanks.shank1.scope.spectroGram1 = nexObj_spectroGram(nexon, nexon.console.NPXLS.shanks.shank1,PSD_trial,"PSD_cwt",f_psd, t_psd);
end