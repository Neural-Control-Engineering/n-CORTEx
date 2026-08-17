function nexFit_umap(mdlObj, args)

    % CFG HEADER
    n_components   = args.n_components;   % default = 3
    n_neighbors    = args.n_neighbors;    % default = 15
    min_dist       = args.min_dist;       % default = 0.1
    nPCAComponents = args.nPCAComponents; % default = 0

    disp("fitting umap...");
    np    = py.importlib.import_module("numpy");
    DM    = mdlObj.DM;
    DM_py = np.array(DM);
    mdlObj.Scaler.model = mdlObj.Scaler.model.fit(DM_py);
    DM_scaled = mdlObj.Scaler.model.transform(DM_py);

    % Optional internal PCA reducer (PCA -> UMAP)
    if nPCAComponents > 0
        decomp = py.importlib.import_module('sklearn.decomposition');
        pca    = decomp.PCA(int32(nPCAComponents));
        pca    = pca.fit(DM_scaled);
        if isempty(mdlObj.Reducer), mdlObj.Reducer = struct(); end
        mdlObj.Reducer.model = pca;
        DM_scaled = pca.transform(DM_scaled);
    else
        mdlObj.Reducer = [];
    end

    mdlObj.model.set_params(pyargs( ...
        'n_components', int32(n_components), ...
        'n_neighbors',  int32(n_neighbors), ...
        'min_dist',     min_dist ...
    ));
    mdlObj.model = mdlObj.model.fit(DM_scaled);
end
