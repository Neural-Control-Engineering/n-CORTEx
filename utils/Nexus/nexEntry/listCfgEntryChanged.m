function listCfgEntryChanged(src, event, key, selectionBus)
    % update selection index    
    selectionBus.selections.(key) = src.Value;
    % update Parent
    if ismethod(selectionBus.Parent,"updateScope")
        switch class(selectionBus.Parent)           
            case "nexObj_selectionBus"
                selectionVal = src.String{src.Value};
                selectionID = key;
                selectionBus.Parent.updateScope(selectionID, selectionVal);    
            otherwise
                % selectionBus.Parent.updateScope();    
        end
    end
end