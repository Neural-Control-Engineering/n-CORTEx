function relayToTargetProxies(proxObj, methodID, pyd, sze)
    tgProxies = proxObj.proxon.index_type2;
    tgProxFields = fieldnames(tgProxies);
    for i = 1:length(tgProxFields)
        tgProxFN = tgProxFields{i};
        tgProxies.(tgProxFN).(methodID)(pyd, sze);
    end
end