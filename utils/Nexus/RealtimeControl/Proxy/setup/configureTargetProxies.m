function configureTargetProxies(proxon, expmntCfg)
    % proxyFieldNames_type1 = fieldnames(proxon.index_type1);
    % for i = 1:length(proxyFieldNames_typeI)
    %     proxyFieldName = proxyFieldNames_type1{i};    
    %     proxObj = proxon.index_type1.(proxyFieldName);
    % end
    targetFieldNames = fieldnames(expmntCfg.targets);
    for i = 1:length(targetFieldNames)
        targetID = targetFieldNames{i};
        proxyID = str2func(sprintf("proxy_%s",targetID));
        try
            serverIP = expmntCfg.targets.(targetID).ethernetIP;
            proxObj = proxyID(serverIP, proxon.nCORTEx);
            proxon.addProxy(proxObj);
        catch e
            disp(getReport(e));
        end
    end
end