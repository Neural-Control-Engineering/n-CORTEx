function boostEXT_SLRT(params, SLRT)
    % load extractCfg
    load(params.paths.expmntPath_cloud,"extractCfg.m");
    visFcn = extractCfg.EXT.SLRT.visFcn;
    % visualize (according to associated function handle)
    visFcn(params,[],SLRT);
end