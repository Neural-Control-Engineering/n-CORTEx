function setSimulinkCodeGenPath(expModulePath)
    cfg = Simulink.fileGenControl('getConfig');
    cfg.CacheFolder = fullfile(expModulePath);
    cfg.CodeGenFolder = fullfile(expModulePath);
    Simulink.fileGenControl('setConfig', 'config', cfg,'createDir',false);
end