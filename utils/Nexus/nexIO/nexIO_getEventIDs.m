function IDs_events = nexIO_getEventIDs(nexon)
    IDs_events = nexon.console.SLRT.signals.eventAlignmentSelection.selKeys.events;
    IDs_events = arrayfun(@(eventID) split(eventID,"_"),IDs_events,"UniformOutput",false);
    IDs_events = convertCharsToStrings(cellfun(@(eventID) eventID{1},IDs_events,"UniformOutput",false));
    IDs_events = unique(IDs_events);
end