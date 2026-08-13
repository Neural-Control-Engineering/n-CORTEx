function avgingDict = nexSelect_averagingDict(nexon)
% Build the averaging-bus candidate dictionary from the current DTS: the
% unique sessionLabel components (subj/phase/date/site) plus any slrt signal
% tags. Shared by nexSelect_averaging (initial bus build) and
% nexRefresh_averaging (in-place refresh on trial append) so both derive the
% same value lists from one place.
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
    if ismember('signal_types',nexon.console.BASE.DTS.Properties.VariableNames)
        signalTags = dtsIO_listSignals(nexon.console.BASE.DTS, ["tag","affix"]);
        sigTagsDict = dtsIO_buildDictionary(nexon.console.BASE.DTS, signalTags);
        avgingDict = mergeStructs(avgingDict, sigTagsDict);
    end
end
