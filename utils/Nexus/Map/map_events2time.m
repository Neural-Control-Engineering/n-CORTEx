function Map = map_events2time(events)
    % signals = nexon.console.BASE.DTS.signal_types{1};
    % sigTypes = convertCharsToStrings(signals(:,2));
    % sigNames = convertCharsToStrings(signals(:,1));
    % events = sigNames((strcmp(sigTypes,"event")));
    LUT_events = buildLUT_map(events); 
    Map = LUT_events;
end