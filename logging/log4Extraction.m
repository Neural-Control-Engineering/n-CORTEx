function log4Extraction(expmntPath,extractionRow)
    extractionLogDir = dir(fullfile(expmntPath,"Extraction-Logs"));
    for i = 3:length(extractionLogDir)
        extractionLogFile = extractionLogDir(i);        
        load(fullfile(extractionLogFile.folder,extractionLogFile.name),'extractionLog');
        extractionLog = [extractionLog; extractionRow];
        save(fullfile(extractionLogFile.folder,extractionLogFile.name),'extractionLog');
    end
end