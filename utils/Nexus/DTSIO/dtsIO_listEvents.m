function events = dtsIO_listEvents(nexon)
    signals = nexon.console.BASE.DTS.signal_types{1};
    sigTypes = convertCharsToStrings(signals(:,2));
    sigNames = convertCharsToStrings(signals(:,1));
    events = sigNames((strcmp(sigTypes,"event")));
end