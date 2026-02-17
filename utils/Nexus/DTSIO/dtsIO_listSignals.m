function signalIDs = dtsIO_listSignals(DTS, types)
    % for given list of signal types, extract unique signals from DTS
    % column(s)
    signalTypes = DTS.signal_types;
    % get longest signal types list from the signal_types column
    % TEMPORARY TO BE UPDATED TO LIST ALL SIGNAL TYPES ACROSS TRIALS
    [maxLength, idx_maxLen] = max(cellfun(@length, signalTypes));
    list_signals = signalTypes{idx_maxLen};
    typeIDs = convertCharsToStrings(list_signals(:,2)); % hard-coded (unfortunately) second column is now signal types
    signalIDs = convertCharsToStrings(list_signals(:,1));
    idx_typesMatch = ismember(typeIDs, types);
    signalIDs = signalIDs(idx_typesMatch);
    % signalIDs = unique(signal_types(cellfun(@(x) length(x) == maxLength, signal_types)));

end