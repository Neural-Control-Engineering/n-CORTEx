function avgSelection = nexSelect_averaging(nexObj)
    nexon = nexObj.nexon;
    % prepare a dictionary for an averaging bus selection
    sessionLabels = nexon.console.BASE.DTS.sessionLabel;
    avgingDict.subj = parseSessionLabelUnique(sessionLabels,"subj");
    avgingDict.phase = parseSessionLabelUnique(sessionLabels,"phase");
    avgingDict.date = parseSessionLabelUnique(sessionLabels,"date");
    % dynamically retrieve slrt signal types
    % signalTags = dtsIO_listSignals(nexon.console.BASE.DTS, ["tag","affix"]);
    signalTags = dtsIO_listSignals(nexon.console.BASE.DTS, ["tag","affix"]);
    sigTagsDict = dtsIO_buildDictionary(nexon.console.BASE.DTS, signalTags);    
    % merge signal tags with avging dict
    avgingDict = mergeStructs(avgingDict, sigTagsDict);
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