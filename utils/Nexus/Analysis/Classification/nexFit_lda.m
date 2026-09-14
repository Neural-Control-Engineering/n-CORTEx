function nexFit_lda(mdlObj, args)

    % CFG HEADER
    n_components = args.n_components;   % default = 0
    shrinkage    = args.shrinkage;      % default = "auto"

    disp("fitting LDA...");
    np    = py.importlib.import_module("numpy");
    nFeat = size(mdlObj.DM.X, 2);
    % MATLAB's py.* conversion can collapse a genuine [n_samples x 1] column
    % (e.g. a single surviving feature after cropping) into a 1-D (n,)
    % NumPy array instead of 2-D (n,1) — sklearn's fit/transform reject 1-D
    % input outright. Force the shape explicitly using nFeat computed from
    % the MATLAB side (always reliable), rather than trusting the
    % conversion to have preserved it.
    X_py = np.array(mdlObj.DM.X).reshape(int32(-1), int32(nFeat));
    mdlObj.Scaler.model = mdlObj.Scaler.model.fit(X_py);
    X_sc = mdlObj.Scaler.model.transform(X_py);
    if n_components > 0
        mdlObj.model.set_params(pyargs('n_components', int32(n_components)));
    end
    % Shrinkage regularization: 'auto' = Ledoit-Wolf, numeric [0,1], or 'none'
    if ischar(shrinkage) || isstring(shrinkage)
        if ~strcmp(char(shrinkage), 'none')
            mdlObj.model.set_params(pyargs('shrinkage', char(shrinkage)));
        end
    elseif isnumeric(shrinkage)
        mdlObj.model.set_params(pyargs('shrinkage', shrinkage));
    end
    % Use integer-encoded Y from the design matrix (stat2dm_supervised already
    % ran nexOp_labelEncode). Store the key in W so predict() can decode back
    % to string labels after DM is cleared.
    tVar = char(mdlObj.dfID_target);
    mdlObj.W = struct('labelKey', mdlObj.DM.K.(tVar));
    mdlObj.model = mdlObj.model.fit(X_sc, np.array(double(mdlObj.DM.Y)));
end
