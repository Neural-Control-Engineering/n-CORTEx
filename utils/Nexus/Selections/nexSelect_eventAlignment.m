function [eventSelection, IDs_signals, IDs_events] = nexSelect_eventAlignment(nexObj, IDs_signals)
% Build the event alignment selection bus from signal_types metadata.
%
% Resolves signal and event IDs from the trial with the most signal_types
% entries (max-N row), filters both against columns actually present in the
% DTS, then builds "<eventID>_<signalID>" tags for all event×signal pairs.
%
% Returns:
%   eventSelection  — nexObj_selectionBus with key "events" = all tags
%   IDs_signals     — string array of available signal IDs
%   IDs_events      — string array of available event IDs

    DTSCols = string(dtsIO_readDFIDs(nexObj.nexon.console.BASE.DTS));

    % Resolve from signal_types (max-N trial)
    IDs_signals_st = nex_getSignalTypes(nexObj.nexon);
    IDs_events     = nex_getEventTypes(nexObj.nexon);

    % Merge caller-supplied IDs with signal_types results
    IDs_signals = unique([IDs_signals(:); IDs_signals_st(:)], 'stable');

    % Filter events to columns actually present in DTS.
    % Signals are not filtered — missing signal data is handled gracefully
    % by nexSLRT_compileDataFrames, and the event selection must remain
    % usable for aligning other nexObjs even when signal data isn't written yet.
    IDs_events = IDs_events(ismember(IDs_events, DTSCols));

    % Build "<eventID>_<signalID>" tags for all event×signal pairs
    eventTags = strings(0, 1);
    for ei = 1:numel(IDs_events)
        for si = 1:numel(IDs_signals)
            eventTags(end+1) = sprintf("%s_%s", IDs_events(ei), IDs_signals(si)); %#ok<AGROW>
        end
    end
    if isempty(eventTags)
        eventTags = "";
    end

    eventAlignmentDict.events = eventTags;
    keyFields = fieldnames(eventAlignmentDict);
    for i = 1:numel(keyFields)
        key = keyFields{i};
        values = eventAlignmentDict.(key);
        if i == 1
            eventSelection = nexObj_selectionBus(nexObj, key, values);
        else
            eventSelection.addKey(key, values);
        end
    end
end
