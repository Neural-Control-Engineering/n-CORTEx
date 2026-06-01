function model = model_lda()
    da = py.importlib.import_module("sklearn.discriminant_analysis");
    model = da.LinearDiscriminantAnalysis();
end