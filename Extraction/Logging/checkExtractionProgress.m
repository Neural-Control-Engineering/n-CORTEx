function [sessionsLeftToExtract, extractionLog] = checkExtractionProgress(extractionLog, sessionsToExtract, extrctModule)
    % scan for and ignore modalities that have already been extracted
    sessionsLeftToExtract = struct;
    sessions = sessionsToExtract.sessions;
    extrctModCol = sprintf("Extracted_%s",extrctModule);
    if all(~ismember(extractionLog.Properties.VariableNames,extrctModCol))
        extractionLog.(extrctModCol) = repelem(0,height(extractionLog))';
    end
    unextractedCondition = (contains(extractionLog.SessionName,sessions)) & (extractionLog.(extrctModCol)==0);
    sessionsLeftToExtract.sessions = extractionLog(unextractedCondition,:).SessionName;
end