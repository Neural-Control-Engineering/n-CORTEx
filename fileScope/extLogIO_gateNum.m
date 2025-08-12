function gX = extLogIO_gateNum(sessionLabel, experiment, projDir_cloud, projDir_local)
    gX = 0;
    if ~strcmp(experiment,"None")
        ExtractionLogPath = fullfile(projDir_cloud,"Experiments", experiment,"Extraction-Logs");
        extractionLogPath_local = fullfile(projDir_local,"Experiments",experiment,"Extraction-Logs");
        extractionLogs_cloud = dir(ExtractionLogPath);
        extractionLogs_local = dir(extractionLogPath_local);
        T_extLocal = struct2table(extractionLogs_local);
        T_extCloud = struct2table(extractionLogs_cloud);              
        if ~isempty(extractionLogs_cloud) | ~isempty(extractionLogs_local)
            extractionLog_RAW_local = T_extLocal(contains(T_extLocal.name,"RAW"),:);
            isFileLocal = isfile(fullfile(extractionLog_RAW_local.folder,extractionLog_RAW_local.name));
            extractionLog_RAW_cloud = T_extCloud(contains(T_extCloud.name,"RAW"),:);
            isFileCloud = isfile(fullfile(extractionLog_RAW_cloud.folder,extractionLog_RAW_cloud.name));
            % if exist(fullfile(extractionLog.folder,extractionLog.name),"file")
            if isFileLocal || isFileCloud
                % extractionLog = readtable(fullfile(extractionLog.folder,extractionLog.name),"Delimiter",",");
                try
                    extractionLog_cloud = readtable(string(fullfile(extractionLog_RAW_cloud.folder,extractionLog_RAW_cloud.name)),"Delimiter",",");
                catch  
                    extractionLog_cloud = [];
                end
                try
                    extractionLog_local = readtable(string(fullfile(extractionLog_RAW_local.folder,extractionLog_RAW_local.name)),"Delimiter",",");
                catch        
                    extractionLog_local = [];
                end
                % extractionLog = [extractionLog_local; extractionLog_cloud];
                extractionLog = mergeT_vertical(extractionLog_local, extractionLog_cloud);
                sessionLabels = extractionLog(:,"SessionName");
                sessionLabels = unique(convertCharsToStrings(sessionLabels));
                ungatedSessLbls = regexprep(table2cell(sessionLabels),"_g\d+","");
                gX = sum((strcmp(table2array(table(ungatedSessLbls)),sessionLabel)));
            else
                gX = 0;
            end
        else
            disp("WARNING: The selected project does not have an extraction log for this experiment \n")
            disp("Please build an experiment directory for the selected project");
        end
    end
end