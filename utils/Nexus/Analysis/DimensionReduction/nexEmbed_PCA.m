function nex_embedPCA(X, Y, args)
    % PCANOISERM - computes PCA components from data   
    
    % CFG HEADER
    n_components = args.n_components; % default = 10
    n_components = py.int(n_components);
    pcaModule = py.importlib.import_module('nexEmbed_PCA');    
    X_array = py.numpy.array(X);
    
    embedding = pcaModule.embedPCA(X_array, n_components);
    
end