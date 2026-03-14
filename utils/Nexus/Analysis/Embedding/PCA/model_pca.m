function model = model_pca()
    decomp_sklearn = py.importlib.import_module('sklearn.decomposition');
    model = decomp_sklearn.PCA();
end