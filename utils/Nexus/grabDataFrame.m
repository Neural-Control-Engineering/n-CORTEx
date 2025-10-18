function dataFrame = grabDataFrame(nexon, dfID, dtsIdx)
    router = nexon.console.BASE.router;
    try
        idxCond = contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.subject) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.date) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.phase) & (str2double(router.entryParams.trial)==nexon.console.BASE.DTS.trialNumber);
    catch
        idxCond = contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.subj) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.date) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.phase) & (str2double(router.entryParams.trial)==nexon.console.BASE.DTS.trialNumber);
    end
    if isempty(dtsIdx)
        dtsIdx = find(idxCond);    
    end
    % Plot initial traces
    dfRow = nexon.console.BASE.DTS(dtsIdx,:);
    try
        dataFrame = dfRow.(dfID);
        if strcmp(class(dataFrame),"cell")
            dataFrame = dataFrame{1};
        end
    catch e
        % disp(getReport(e))
        dataFrame = [];
    end
end