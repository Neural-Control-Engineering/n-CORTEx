function data_psd = extractPSD(params, data_ft, method )
    %% choose method = MTMFFT or MTMCONVOL
    cfgLabel = sprintf('ftCfg_%s', method);
    cfg = params.(cfgLabel);
    cfg.output = 'pow';
    data_psd = ft_freqanalysis(cfg, data_ft);    
end