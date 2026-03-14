function nexFit_ssm(mdlObj, args)
    
    % CFG HEADER
    stateDim = args.stateDim; % default = 3
    numIters = args.numIters; % default = 20
    partialFit = args.partialFit; % default = 0

    np = py.importlib.import_module('numpy');

    switch  partialFit
        case 0
            % stack all samples
            % X = nexOp_stackSamples(mdlObj.Parent.STAT);
            % emissions = np.asarray(X);
            DM = mdlObj.DM; % retrieve design matrix
            DM_py = mdlObj.py.np.array(DM);
            % DM_scaled = mdlObj.py.stdScaler.fit_transform(DM_py);
            mdlObj.W = mdlObj.model.fit(DM_py, py.int(stateDim), py.int(numIters));
        case 1
            error("partial fit not enabled");
    end
    
    % Invalidate caches
    % py.importlib.invalidate_caches;
    % 
    % % Reload modules
    % pytafix = py.importlib.import_module('pytafix'); 
    % py.importlib.reload(pytafix.ssm.lgssm_dynamax);
    % py.importlib.reload(pytafix.ssm);
    % py.importlib.reload(pytafix);
    % % model = py.importlib.import_module('pytafix.ssm.lgssm_dynamax');            
    % % py.importlib.reload(model);
    % mdlObj.model = pytafix.ssm.LGSSM;
    % 
    % Re-instantiate your object
    % ssm_obj = pytafix.ssm.LGSSM();
end