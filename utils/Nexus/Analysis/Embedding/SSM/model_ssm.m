function model = model_ssm()

    % CFG HEADER

    py.importlib.invalidate_caches;    
    pytafix = py.importlib.import_module('pytafix');
    py.importlib.reload(pytafix);
    model = py.importlib.import_module('pytafix.ssm.lgssm_dynamax');            
    model = model.LGSSM;
    % model = linear_gaussian_ssm.LinearGaussianSSM;        

end