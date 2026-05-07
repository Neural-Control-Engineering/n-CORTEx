function events = dtsIO_listEvents(nexon)
    if isfield(nexon.console.BASE.DTS,"signal_types")
        signals = nexon.console.BASE.DTS.signal_types{1};
        sigTypes = convertCharsToStrings(signals(:,2));
        sigNames = convertCharsToStrings(signals(:,1));
        events = sigNames((strcmp(sigTypes,"event")));
    else
        events=[];
    end
end