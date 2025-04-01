function proxyArray = startProxy(params)
    % for each target configured in params, generate a proxy
    targets = fieldnames(params.expmntCfg.targets);
    for i = 1:length(targets)
        target = targets{i};
        proxyID = sprintf("proxy_%s",target);
        proxyInitFcn = str2func(proxyID);
        tgProxies.(proxyID) = proxyInitFcn();
    end
    cmdLUT = params.expmntCfg.cmdLUT_slrt;
    % generate a simulink realtime proxy
    proxyArray.proxy_slrt = proxy_slrt([],cmdLUT,[],tgProxies);
    % partner with a ncortex proxy
    proxyArray.proxy_ncortex = proxy_ncortex(params.ethernetIP,8001,[],[],tgProxies);
    

end