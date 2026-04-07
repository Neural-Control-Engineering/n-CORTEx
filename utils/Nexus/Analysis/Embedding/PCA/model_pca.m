function model = model_pca(nComponents)    
    if nargin < 1
        nComponents = 20;
    end
    decomp_sklearn = py.importlib.import_module('sklearn.decomposition');
    model = decomp_sklearn.PCA(py.int(nComponents),pyargs('whiten',true));
end