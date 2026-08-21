function model = model_pca(nComponents, useGPU)
    if nargin < 1, nComponents = 20; end
    if nargin < 2, useGPU = false; end
    if useGPU
        decomp = py.importlib.import_module('cuml.decomposition');
        model  = decomp.PCA(py.int(nComponents), pyargs('whiten', true, 'output_type', 'numpy'));
    else
        decomp = py.importlib.import_module('sklearn.decomposition');
        model  = decomp.PCA(py.int(nComponents), pyargs('whiten', true));
    end
end