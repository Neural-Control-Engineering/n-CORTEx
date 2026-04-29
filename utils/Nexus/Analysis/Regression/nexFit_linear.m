function nexFit_linear(mdlObj, args)

    % CFG HEADER

    np   = py.importlib.import_module('numpy');
    DM   = mdlObj.DM;
    X_py = np.array(double(DM.X));
    Y_py = np.array(double(DM.Y)).ravel();   % 1-D — required by Lasso, harmless for Ridge/OLS
    mdlObj.model = mdlObj.model.fit(X_py, Y_py);

    r2  = double(mdlObj.model.score(X_py, Y_py));
    msg = sprintf('[nexFit_linear] fit  R²=%.3f  (n=%d, p=%d)', ...
                  r2, size(DM.X,1), size(DM.X,2));

    % Sparsity report for Lasso — how many time/feature bins were selected
    if isprop(mdlObj.model, 'coef_')
        coef = double(np.array(mdlObj.model.coef_));
        nNZ  = sum(coef ~= 0);
        if nNZ < numel(coef)
            msg = sprintf('%s  [Lasso: %d/%d nonzero]', msg, nNZ, numel(coef));
        end
    end
    fprintf('%s\n', msg);
end
