function write2Extrctn(extrctLogPath,sessionLabel,ColName,value,atomicWrite)
    % atomicWrite (optional, default false): when true, writes via
    % writetableAtomic (temp file + movefile) instead of writetable()
    % directly — prevents a corrupted/truncated log if the write is
    % interrupted mid-way (crash, timeout, parallel pool teardown). Off
    % by default so every existing caller keeps its current behavior
    % unchanged; extractEXT.m/extractDTS.m opt in explicitly.
    if nargin < 5 || isempty(atomicWrite), atomicWrite = false; end
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
        if atomicWrite
            writetableAtomic(extractionLog,fullfile(extrctLogPath,extractionLogFile.name));
        else
            writetable(extractionLog,fullfile(extrctLogPath,extractionLogFile.name));
        end
    end

end