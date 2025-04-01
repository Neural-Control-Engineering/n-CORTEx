function S = nex_returnSelectionMask(selectionBus)
    % controlPanel = nexon.console.BASE.controlPanel;
    selKeys = selectionBus.selKeys;
    selections = selectionBus.selections;
    selFields = fieldnames(selectionBus.selKeys);    
    for i = 1:length(selFields)
        key = selFields{i};
        values = selKeys.(key);
        selection = selections.(key);
        selectedVals = values(selection);
        S.(key) = selectedVals;
    end
end