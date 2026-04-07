function DF_out = nexFit_pca(mdlObj, args)
    
    % CFG HEADER    
    nComponents = args.nComponents; % default = 5

    disp("fitting pca...");
    % set args
    mdlObj.model.set_params(pyargs("n_components", int32(nComponents)));
    np = py.importlib.import_module("numpy");    
    % temporary indexing    
    % chanCond = [1:10];
    % DM = mdlObj.DM(:,chanCond);
    DM = mdlObj.DM;
    % DM_py = np.array(mdlObj.DM);
    DM_py = np.array(DM);
    mdlObj.Scaler.model = mdlObj.Scaler.model.fit(DM_py);
    DM_scaled = mdlObj.Scaler.model.transform(DM_py);
    mdlObj.model = mdlObj.model.fit(DM_scaled);
    % switch mode
    %     case 0 % standard PCA
    %         sklearn = py.importlib.import_module('sklearn');
    %         pca = sklearn.decomposition.PCA;
    % 
    %     case 1 % dPCA
    %         dpca = py.importlib.import_module('dPCA');
    % 
    %     case 2 % jPCA
    % end
    
end