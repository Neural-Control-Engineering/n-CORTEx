function freq = fooof(params, lfp)
    % fooof uses fieldtrip toolbox to complete 'Fitting Oscillations One
    % Over Frequency' analysis, returns fractal and oscillatory components
    % of the PSD (in addition to original PSD)
    
    % initialize path settings
    ft_startup;
    
    %% set Configuration Parameters
    % cfg = params.fooof_cfg;
    cfg = params.ftCfg_fooof;
    cfg.method = 'trial';
    ftData = dstore2ftData(params, lfp);
    cfg = params.ftCfg_fooof;
    cfg.pad = "maxperlen";
    % cfg.taper="hanning";
    cfg.taper="sine";
    cfg.tapsmofrq = 2;
    % cfg.foilim = 

    %% FIT PARAMETERS
    [freq] = ft_freqanalysis(cfg, ftData);

    %% UNCOMMENT FOR PLOTTING
%     figure
%     plot(freq.freq, 10*log10(freq.powspctrm))
%     title('fooof Power Spectrum')
   

end