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
    % Use integer-encoded Y from the design matrix (stat2dm_supervised already
    % ran nexOp_labelEncode). Store the key in W so predict() can decode back
    % to string labels after DM is cleared.
    tVar = char(mdlObj.dfID_target);
    mdlObj.W = struct('labelKey', mdlObj.DM.K.(tVar));
    mdlObj.model = mdlObj.model.fit(X_sc, np.array(double(mdlObj.DM.Y)));
end
