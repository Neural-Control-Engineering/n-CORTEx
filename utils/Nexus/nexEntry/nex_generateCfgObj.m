function cfgObj = nex_generateCfgObj(fcn)    
    cfg = extractCfg(fcn);
    cfg.fcn = (fcn);
    cfgObj = nexObj_cfg(cfg);
end