function labelKeys = nex_enumerateSessionLabels(nexon, labelIDs)
    labelKeys = struct;
    for i = 1:length(labelIDs)
        labelID = labelIDs(i);
        sessionLabels = nexon.console.BASE.DTS.sessionLabel;
        uniqueLabels = parseSessionLabelUnique(sessionLabels,labelID);
        for j = 1:length(uniqueLabels)            
            uniqLabel = strrep(uniqueLabels(j),"-","_");
            if isStartsWithDigit(uniqLabel)
                uniqLabel = strcat(extractBefore(labelID,2),uniqLabel);
            end
            labelKeys.(labelID).(uniqLabel) = j;
        end
    end
end