function isMember = nex_isDtsMember(nexon, dtsMemberID, matchArgs, dtsIdx)    
    argsID = sprintf("%s_args", dtsMemberID);
    dfArgs = grabDataFrame(nexon, argsID, dtsIdx);
    matchLogic = ismember(fieldnames(dfArgs),fieldnames(matchArgs));
    if all(matchLogic)
        isMember = 1;
    else
        isMember = 0;
    end    
end