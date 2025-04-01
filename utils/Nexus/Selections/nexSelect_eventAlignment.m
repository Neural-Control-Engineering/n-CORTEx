function eventSelection = nexSelect_eventAlignment(nexObj_slrtTc)
    dfIDs = nexObj_slrtTc.dfID;
    DTSCols = nexObj_slrtTc.nexon.console.BASE.DTS.Properties.VariableNames;
    eventTags = [];
    for i = 1:length(dfIDs)
        dfID = dfIDs(i);
        eventID = sprintf("aligned_%s",dfID);
        eventMatches = DTSCols(find(contains(DTSCols,eventID)));
        eventLabels = cellfun(@(x) split(x,"_"), eventMatches,"UniformOutput",false);
        eventLabels = cellfun(@(x) x{1}, eventLabels,"UniformOutput",false);
        eventLabels = unique(convertCharsToStrings(eventLabels));
        eventTags = [eventTags; arrayfun(@(x) sprintf("%s_%s",x,dfID), eventLabels,"UniformOutput",true)'];        
    end
    eventAlignmentDict.events = eventTags;
    keyFields = fieldnames(eventAlignmentDict);
    for i=1:length(keyFields)
        key = keyFields{i};
        values = eventAlignmentDict.(key);
        if i==1
            eventSelection = nexObj_selectionBus(nexObj_slrtTc, key, values);
        else
            eventSelection.addKey(key, values);
        end
    end
end