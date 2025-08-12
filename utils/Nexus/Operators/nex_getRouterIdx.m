function idxCond = nex_getRouterIdx(nexon)
    router = nexon.console.BASE.router;
    try
        idxCond = contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.subject) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.date) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.phase) & (str2double(router.entryParams.trial)==nexon.console.BASE.DTS.trialNumber);
    catch
        idxCond = contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.subj) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.date) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.phase) & (str2double(router.entryParams.trial)==nexon.console.BASE.DTS.trialNumber);
    end
end