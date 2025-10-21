function isMember = nex_isDtsMember(nexon, dtsMemberID, matchArgs, dtsIdx)    
    argsID = sprintf("%s_args", dtsMemberID);
    
    % retrieve potential match config (if not empty)
    dfArgs = grabDataFrame(nexon, argsID, dtsIdx);    
    if isempty(dfArgs)
        dfArgs = struct;
    end

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
    if isempty(valueMatchLogic) % if no matches at all
        isMember = 0;
    else
        isMember = all(valueMatchLogic==1);
    end
end