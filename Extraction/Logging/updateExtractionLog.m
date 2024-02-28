function extractionLog = updateExtractionLog(extractionLog, sessionLabel, ColName, Value, initVal)
    % given path to extraction log, as determined by projectDir and
    % modality, write a new session into the extraction log, initialized as
    % 0
    if all(~ismember(extractionLog.Properties.VariableNames,ColName))
        extractionLog.(ColName) = repelem(initVal,height(extractionLog))';
    else        
    end
    extractionLog(contains(extractionLog.SessionName,sessionLabel),:).(ColName)=Value;  
    
end