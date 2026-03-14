function nexFit_logistic(mdlObj, args)

    % CFG HEADER

    np = py.importlib.import_module("numpy");
    DM = mdlObj.DM;
    X = DM.X;
    Y = DM.Y;
    X_py = np.array(X);
    Y_py = np.array(Y);    
    disp("fitting logistic regression");
    mdlObj.model = mdlObj.model.fit(X_py, Y_py);    
end