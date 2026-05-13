function avgSelection = nexSelect_averaging(nexObj)
    nexon = nexObj.nexon;
    % prepare a dictionary for an averaging bus selection
    sessionLabels = nexon.console.BASE.DTS.sessionLabel;
    avgingDict.subj = parseSessionLabelUnique(sessionLabels,"subj");
    avgingDict.phase = parseSessionLabelUnique(sessionLabels,"phase");
    avgingDict.date = parseSessionLabelUnique(sessionLabels,"date");
    try
        site = parseSessionLabelUnique(sessionLabels,"site");        
        if ~isempty(site) && ~strcmp(site,"")
            avgingDict.sit=site;
        end
    catch    
    end
    % dynamically retrieve slrt signal types
    % signalTags = dtsIO_listSignals(nexon.console.BASE.DTS, ["tag","affix"]);
    if ismember('signal_types',nexon.console.BASE.DTS.Properties.VariableNames)
        signalTags = dtsIO_listSignals(nexon.console.BASE.DTS, ["tag","affix"]);
        sigTagsDict = dtsIO_buildDictionary(nexon.console.BASE.DTS, signalTags);    
        avgingDict = mergeStructs(avgingDict, sigTagsDict);
    end
    % merge signal tags with avging dict    
    keyFields = fieldnames(avgingDict);
    for i=1:length(keyFields)
        key = keyFields{i};
        values = avgingDict.(key);
        if i==1
            avgSelection = nexObj_selectionBus(nexObj, key, values);
        else
            avgSelection.addKey(key, values);
        end
    end
end