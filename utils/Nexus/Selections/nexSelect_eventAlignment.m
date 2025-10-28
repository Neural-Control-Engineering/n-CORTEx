function [eventSelection, IDs_signals] = nexSelect_eventAlignment(nexObj, IDs_signals)
    % dfIDs = nexObj_slrtTc.dfID;
    DTSCols = nexObj.nexon.console.BASE.DTS.Properties.VariableNames;
    eventTags = [];
    % ID_signals = nexObj.nexon.console.BASE.DTS.signal_types;
    IDs_signals = [IDs_signals; nex_getSignalTypes(nexObj.nexon)];
    % dfIDs_signals = dtsIO_filter_slrtSignals(DTSCols);
    % for i = 1:length(dfIDs)
    for i = 1:length(IDs_signals)
        % dfID = dfIDs(i);
        dfID = IDs_signals(i);
        eventID = sprintf("aligned_%s",dfID);
        eventMatches = DTSCols(find(contains(DTSCols,eventID)));
        eventLabels = cellfun(@(x) split(x,"_"), eventMatches,"UniformOutput",false);
        eventLabels = cellfun(@(x) x{1}, eventLabels,"UniformOutput",false);
        eventLabels = unique(convertCharsToStrings(eventLabels));
        eventTags = [eventTags; arrayfun(@(x) sprintf("%s_%s",x,dfID), eventLabels,"UniformOutput",true)'];        
    end
    eventAlignmentDict.events = eventTags;
    % build selection bus
    keyFields = fieldnames(eventAlignmentDict);
    for i=1:length(keyFields)
        key = keyFields{i};
        values = eventAlignmentDict.(key);
        if i==1
            eventSelection = nexObj_selectionBus(nexObj, key, values);
        else
            eventSelection.addKey(key, values);
        end
    end
end