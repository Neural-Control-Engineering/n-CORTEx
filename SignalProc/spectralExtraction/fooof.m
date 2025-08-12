function freq = fooof(params, lfp, f)
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
    cfg.taper="hanning";
    % cfg.taper="sine";
    cfg.tapsmofrq = 2;
    % cfg.foilim =     

    %% FIT PARAMETERS
    switch cfg.freqAnalysisMethod
        case "auto"
            [freq] = ft_freqanalysis(cfg, ftData);
        case "pwelch"
            cfg.Fs = 500;
            cfg.win = 400;
            [freq] = fooof_pwelch(cfg, ftData);
        case "preFFT"
            % lfp is now a precalculated psd (misnomer)
            hOT=1;
            ss= size(lfp);
            TF = reshape(lfp,[ss(1),1,ss(2)]); %e.g. size N x 1 x nFfts psd            
            [fs, fg] = process_fooof('FOOOF_matlab', TF, f, cfg.opt, hOT);
            % for i = 1:10:384
            %     figure;
            %     plot(fs, log10(fg(i).fooofed_spectrum));
            %     hold on
            %     plot(fs, fg(i).power_spectrum);
            %     fCond = find(f_pmt >= min(fs) & f_pmt <= max(fs));
            %     plot(f_pmt(fCond), log10(PMT(fCond,1)));
            % end
            freq.fooofparams = fg';
            freq.freq = fs;            
            freq.powspctrm = lfp;
    end
        

    %% UNCOMMENT FOR PLOTTING
%     figure
%     plot(freq.freq, 10*log10(freq.powspctrm))
%     title('fooof Power Spectrum')
   

end