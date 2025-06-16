function nex_removeGraphic(nexObj, graphic, ID_graphic, ID_filter)
    % filter
    ID_graphic = string(ID_graphic);
    if strcmp(ID_graphic,sprintf("%s_%s",nexObj.classID,ID_filter))
        return
    else
        delete(graphic);        
    end    
end