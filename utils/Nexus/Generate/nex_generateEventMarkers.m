function graphics = nex_generateEventMarkers(nexObj, axis)
    % IDs_events = nexIO_getEventIDs(nexObj.nexon);
    LUT_eventMap = nexObj.nexon.console.SLRT.signals.pMap_time.Map;
    IDs_events = LUT_eventMap.event;
    Src = nexObj.nexon.console.BASE.controlPanel;
    for i = 1:length(IDs_events)
        eventID = IDs_events(i);
        eventColor = LUT_eventMap.color(i);
        % wrap these with update methods        
        % graphics.(sprintf("xMarker_event_%s",eventID))=xline(axis,1,"Color",eventColor);
        graphics.(sprintf("xMarker_event_%s",eventID))=nexObj_xMarker_event(nexObj, axis, Src, eventID, eventColor);
    end
end