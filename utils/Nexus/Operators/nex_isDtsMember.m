function isMember = nex_isDtsMember(nexon, dtsMemberID, matchArgs, dtsIdx)    
    argsID = sprintf("%s_args", dtsMemberID);
    dfArgs = grabDataFrame(nexon, argsID, dtsIdx);
    matchLogic = ismember(fieldnames(dfArgs),fieldnames(matchArgs));
    % only compare identical fields
    % if all(matchLogic)
    %     isMember = 1;
    % else
    %     isMember = 0;
    % end    
    valueMatchLogic = [];
    dfFields = fieldnames(dfArgs);    
    for i = 1:length(matchLogic)
        dfField = dfFields{i};
        isMemberMatch = matchLogic(i);
        if isMemberMatch
            dfVal = dfArgs.(dfField);
            matchVal = matchArgs.(dfField);
            if dfVal == matchVal
                valueMatchLogic = [valueMatchLogic; 1];
            else
                valueMatchLogic = [valueMatchLogic; 0];
            end
        end
    end
    isMember = all(valueMatchLogic==1);
end