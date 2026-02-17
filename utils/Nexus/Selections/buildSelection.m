function selection =  buildSelection(nexObj, dict, initSel)
    if nargin < 3
        initSel = 1;            
    end
    keyFields = fieldnames(dict);
    for i=1:length(keyFields)
        key = keyFields{i};
        values = dict.(key);
        if i==1
            selection = nexObj_selectionBus(nexObj, key, values, initSel);
        else
            selection.addKey(key, values, initSel);
        end
    end
end