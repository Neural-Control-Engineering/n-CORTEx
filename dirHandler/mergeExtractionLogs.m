function mergeExtractionLogs(paths, expmnt, extLogDir_local, extLogDir_cloud)
    % update cloud extraction log with local 'cached' extraction log
    extLogs = string(categorize(extLogDir_local,"extraction_log.csv"));
    expmntPath_cloud = fullfile(paths.projDir_cloud,"Experiments",expmnt);
    for i = 1:length(extLogs)
        extLogFilename = extLogs(i);
        extractionLog_local = readtable(fullfile(extLogDir_local,extLogFilename),"Delimiter",",");
        extractionLog_cloud = readtable(fullfile(extLogDir_cloud,extLogFilename),"Delimiter",",");
        extractionLog_local = extractionLog_local(~ismember(extractionLog_local.SessionName,extractionLog_cloud.SessionName),:);
        for j = 1:height(extractionLog_local)
            extractionRow = extractionLog_local(j,:);
            log4Extraction(expmntPath_cloud, extractionRow, "csv");
        end
        % save local extractionLog back
        writetable(extractionLog_local, fullfile(paths.projDir_local,"Experiments",expmnt,"Extraction-Logs",extLogFilename));
    end
end