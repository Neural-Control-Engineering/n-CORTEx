function SLRT = loadEXT_SLRT(params, session)
    slrtLog = load(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","RAW","SLRT",session)); 
    SLRT.data = slrtLog.realtimeLog.data;
    SLRT.meta = slrtLog.realtimeLog.metadata;
end