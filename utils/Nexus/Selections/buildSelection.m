function buildSelection(nexObj, dict)
    keyFields = fieldnames(dict);
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