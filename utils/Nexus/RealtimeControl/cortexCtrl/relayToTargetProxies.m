function relayToTargetProxies(proxObj, methodID, pyd, sze)
    tgProxies = proxObj.proxon.index_type2;
    tgProxFields = fieldnames(tgProxies);
    for i = 1:length(tgProxFields)
        tgProxFN = tgProxFields{i};
        try
            tgProxies.(tgProxFN).(methodID)(pyd, sze);
        catch e
            disp(getReport(e));
        end
    end
end