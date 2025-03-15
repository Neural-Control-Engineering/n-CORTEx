function sessionLabel =  nex_findSessionLabel(nexon, labelData, labelKeys)
    % 
    keyFields = fieldnames(labelKeys)
    labelStrings = [];
    for i = 1:length(keyFields)
        keyField = keyFields{i};
        keyVals = labelKeys.(keyField);
        keyVals = struct2table(keyVals);
        colIdx = find(table2array(keyVals)==labelData.(keyField));
        keyVal = keyVals.Properties.VariableNames{colIdx};
        % reformat
        if isstrprop(keyVal(2),"digit")
            keyVal = keyVal(2:end);
        end
        keyVal = strrep(keyVal,"_","-");        
        labelStrings = [labelStrings, sprintf("%s--%s",keyField, keyVal)]
    end
    idx = find(ismember(nexon.console.BASE.DTS.sessionLabel,labelStrings));
    [rows, qStrs] = ndgrid(1:size(nexon.console.BASE.DTS.sessionLabel,1), 1:size(labelStrings,2));
    matchMask = arrayfun(@(row, qStr) contains(nexon.console.BASE.DTS.sessionLabel(row), labelStrings(qStr)), rows, qStrs);
    matchIdxs = find(all(matchMask,2));
    trialNums = matchIdxs - min(matchIdxs)+1;
    trialIdx = find(trialNums == labelData.trial);
    trialRowIdx = matchIdxs(trialIdx);
    sessionLabel = nexon.console.BASE.DTS.sessionLabel(trialRowIdx);

end