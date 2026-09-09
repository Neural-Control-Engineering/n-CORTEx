function nexFit_lda(mdlObj, args)

    % CFG HEADER
    n_components = args.n_components;   % default = 0

    disp("fitting LDA...");
    np   = py.importlib.import_module("numpy");
    X_py = np.array(mdlObj.DM.X);
    mdlObj.Scaler.model = mdlObj.Scaler.model.fit(X_py);
    X_sc = mdlObj.Scaler.model.transform(X_py);
    if n_components > 0
        mdlObj.model.set_params(pyargs('n_components', int32(n_components)));
    end
    % Pass original string labels — sklearn handles them natively so
    % model.predict returns strings that directly match the STAT target column,
    % no integer encoding/decoding needed.
    tVar = char(mdlObj.dfID_target);
    Y_str = cellstr(string(mdlObj.TRAIN.STAT.(tVar)));
    mdlObj.model = mdlObj.model.fit(X_sc, np.array(Y_str));
end
