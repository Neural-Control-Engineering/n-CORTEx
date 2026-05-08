function listCfgEntryChanged(src, event, key, selectionBus)
    selectionBus.selections.(key) = src.Value;
    parent = selectionBus.Parent;
    if isa(parent, 'nexObj_selectionBus')
        % Items bus of nexObj_categorical — enumerate items for the new selection
        parent.updateScope(char(key), src.String{src.Value(end)});
    elseif ismethod(parent, 'visualize')
        parent.visualize();
    end
end
