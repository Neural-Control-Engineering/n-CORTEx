function model = model_logistic()
    sklearn = py.importlib.import_module("sklearn");
    model = sklearn.linear_model.LogisticRegression();
end