function log4Extraction(projPath,extractionRow)
    extractionLogDir = dir(fullfile(projPath,"Extraction-Logs"));
    for i = 3:length(extractionLogDir)
        extractionLogFile = extractionLogDir(i);        
        load(fullfile(extractionLogFile.folder,extractionLogFile.name),'extractionLog');
        extractionLog = [extractionLog; extractionRow];
        save(fullfile(extractionLogFile.folder,extractionLogFile.name),'extractionLog');
    end
end