function rewriteExtractionLogs(params)
    expmntPath = params.paths.expmntPath_cloud;
    extractionLogDir = dir(fullfile(expmntPath,"Extraction-Logs"));
    for i = 3:length(extractionLogDir)
        extractionLogFile = extractionLogDir(i);      
        extractionLog = readtable(fullfile(extractionLogFile.folder,extractionLogFile.name),"Delimiter",',');
        % replace mat with ''
        sessionNameNew = cellfun(@(x) strrep(x,".mat",""), extractionLog.SessionName, "UniformOutput",false);
        extractionLog.SessionName = sessionNameNew;                
        writetable(extractionLog,fullfile(extractionLogFile.folder,extractionLogFile.name));
            
        
    end
end