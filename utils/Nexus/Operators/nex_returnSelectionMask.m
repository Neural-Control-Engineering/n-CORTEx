function S = nex_returnSelectionMask(selectionBus)
    % controlPanel = nexon.console.BASE.controlPanel;
    try
        selKeys = selectionBus.selKeys;
    catch
        % keyboard
    end
    selections = selectionBus.selections;
    selFields = fieldnames(selectionBus.selKeys);    
    for i = 1:length(selFields)
        key = selFields{i};
        values = selKeys.(key);
        selection = selections.(key);
        try
            selectedVals = values(selection);
        catch e
            % keyboard
            disp(getReport(e));
        end
        S.(key) = selectedVals;
    end
end