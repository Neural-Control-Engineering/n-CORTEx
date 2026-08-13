function avgSelection = nexSelect_averaging(nexObj)
    nexon = nexObj.nexon;
    % prepare a dictionary for an averaging bus selection
    avgingDict = nexSelect_averagingDict(nexon);
    keyFields = fieldnames(avgingDict);
    for i=1:length(keyFields)
        key = keyFields{i};
        values = avgingDict.(key);
        if i==1
            avgSelection = nexObj_selectionBus(nexObj, key, values);
        else
            avgSelection.addKey(key, values);
        end
    end
end