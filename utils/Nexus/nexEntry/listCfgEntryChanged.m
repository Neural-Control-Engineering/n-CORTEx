function listCfgEntryChanged(src, event, key, selectionBus)
    % update selection index    
    selectionBus.selections.(key) = src.Value;
    % update Parent
    selectionBus.Parent.updateScope(selectionBus.Parent.nexon);
end