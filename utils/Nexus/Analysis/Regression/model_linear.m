function model = model_linear()
    mod = py.importlib.import_module('sklearn.linear_model');
    model = mod.LinearRegression();
end
