function nexFit_linear(mdlObj, args)
    np  = py.importlib.import_module('numpy');
    DM  = mdlObj.DM;
    X_py = np.array(double(DM.X));
    Y_py = np.array(double(DM.Y));
    mdlObj.model = mdlObj.model.fit(X_py, Y_py);
    fprintf('[nexFit_linear] fit  R²=%.3f  (n=%d, features=%d)\n', ...
        double(mdlObj.model.score(X_py, Y_py)), size(DM.X,1), size(DM.X,2));
end
