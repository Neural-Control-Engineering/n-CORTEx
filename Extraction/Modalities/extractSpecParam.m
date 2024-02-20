function data_specParam = extractSpecParam(params, data_ft)
    cfg = params.ftCfg_fooof;
    data_specParam = ft_freqanalysis(cfg, data_ft);
end