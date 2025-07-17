function graphics = nex_generateEventMarkers(nexObj, axis)
    IDs_events = nexIO_getEventIDs(nexObj.nexon);
    LUT_tMAP = nexObj.nexon.console.SLRT.signals.pMap_time.Map;
    for i = 1:length(IDs_events)
        eventID = IDs_events(i);
        eventColor = LUT_tMAP.color(i);
        % wrap these with update methods
        graphics.(sprintf("xLine_event_%s",eventID))=xline(axis,1,"Color",eventColor);
    end
end