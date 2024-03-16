function extractionLog = updateExtractionLog(extractionLog, sessionLabel, ColNames, Value, initVal)
    % given path to extraction log, as determined by projectDir and
    % modality, write a new session into the extraction log, initialized as
    % 0
    for i = 1:length(ColNames)
        ColName = ColNames(i);
        if all(~ismember(extractionLog.Properties.VariableNames,ColName))
            extractionLog.(ColName) = repelem(initVal,height(extractionLog))';
        else        
        end
        if ~isempty(sessionLabel)
            extractionLog(contains(extractionLog.SessionName,sessionLabel),:).(ColName)=Value;  
        end
    end        
end