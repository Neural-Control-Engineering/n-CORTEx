function write2Extrctn(extrctLogPath,sessionLabel,ColName,value)
    extractionLogDir = dir(fullfile(extrctLogPath,"*.csv"));
    for i = 1:length(extractionLogDir)
        extractionLogFile = extractionLogDir(i);
        extractionLog = readtable(fullfile(extrctLogPath,extractionLogFile.name),"Delimiter",",");
        % if all(isnan(extractionLog.(ColName)))
        %     extractionLog.(ColName) = repelem("",height(extractionLog))';        
        % end        
        % Col = extractionLog.(ColName);
        % Col(isempty(Col)) = '';
        % Col(isnan(Col)) = '';
        % Col{contains(extractionLog.SessionName, sessionLabel),:} = convertStringsToChars(value);
        % extractionLog.(ColName) = Col;
        extractionLog(contains(extractionLog.SessionName, sessionLabel),:).(ColName) = cellstr(value);%convertStringsToChars(value);
        writetable(extractionLog,fullfile(extrctLogPath,extractionLogFile.name));
    end
  
end