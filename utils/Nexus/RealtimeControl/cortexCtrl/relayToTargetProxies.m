function relayToTargetProxies(proxObj, pyd, sze)
    tgProxies = proxObj.proxon.index_type2;
    tgProxFields = fieldnames(tgProxies);
    for i = 1:length(tgProxFields)
        tgProxFN = tgProxFields{i};
        tgProxies.(tgProxFN).loadTSeries(pyd, sze);
    end
end