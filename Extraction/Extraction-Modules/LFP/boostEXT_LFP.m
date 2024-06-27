function boostEXT_LFP(params, LFP)
    % load extractCfg
    load(params.paths.expmntPath_cloud,"extractCfg.m");
    % visualize (according to associated function handle)
    visFcn = extractCfg.EXT.LFP.visFcn;    
    visFcn(params,[],LFP);
    
end