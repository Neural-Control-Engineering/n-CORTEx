function dataFrame = grabDataFrame(nexon, dfID)
    router = nexon.console.BASE.router;
    idxCond = contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.subject) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.date) & contains(nexon.console.BASE.DTS.sessionLabel,router.entryParams.phase) & (str2double(router.entryParams.trial)==nexon.console.BASE.DTS.trialNumber);
    dtsIdx = find(idxCond);    
    % Plot initial traces
    dfRow = nexon.console.BASE.DTS(dtsIdx,:);
    try
        dataFrame = dfRow.(dfID);
        if strcmp(class(dataFrame),"cell")
            dataFrame = dataFrame{1};
        end
    catch e
        disp(e)
        dataFrame = [];
    end
end