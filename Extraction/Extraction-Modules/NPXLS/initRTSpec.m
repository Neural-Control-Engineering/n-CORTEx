function specObj = initRTSpec(params, specModel)
    % configure python interpreter
    pyVersion = "/home/user/miniconda3/envs/rtspec/bin/python";
    pyenv(Version=pyVersion);    
    % Add Neural Network Modules to python path
    lstmFolderPath = "/home/user/Code_Repo/n-CORTEx/NeuralNetworks/RTSpec/Models";  % Update this path to the folder containing LSTM.py
    py.sys.path().append(lstmFolderPath);
    % import rtSpec module
    cd(fullfile(params.paths.repo_path,"utils/RTSpec/"));
    rtSpec = py.importlib.import_module("rt_spec");
    % instantiation (parameter definitions)
    modelPath = "/home/user/Code_Repo/n-CORTEx/utils/RTSpec/Models/biLSTM50.pth";
    pyParams = struct;
    pyParams.modelPath = modelPath;
    pyParams = structToDict(pyParams);
    % model object
    % rtSpec(pyParams, modelPath)
    % test implementation
    specObj = rtSpec.RTSpec(pyParams, modelPath);    
    % psdTest = reshape(psd,1,1,195);
    psdTensor = py.torch.tensor(psd, pyargs('dtype', py.torch.float32));
    pTen = psdTensor.unsqueeze(uint8(-1));
    pTen = pTen.unsqueeze(uint8(-1));
    % psdTensor = psdTensor.view(1, 1, 195);  % Reshape to (1, 1, 195)
    % test implementation (assuming psd is defined somewhere)
    sortObj = specObj.fit(pTen.cuda());
end