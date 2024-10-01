function sessionDTS = grabSession(nexon)
    router = nexon.console.BASE.router;
    idxCond = contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.subject) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.phase) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.date);
    dtsIdx = find(idxCond);    
    % Plot initial traces
    sessionDTS = nexon.console.BASE.DTS(dtsIdx,:);
end