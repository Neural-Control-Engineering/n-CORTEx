function log4Extraction(expmntPath,extractionRow,ftype)
    extractionLogDir = dir(fullfile(expmntPath,"Extraction-Logs"));
    for i = 3:length(extractionLogDir)
        extractionLogFile = extractionLogDir(i); 
        switch ftype
            case 'mat'
                load(fullfile(extractionLogFile.folder,extractionLogFile.name),'extractionLog');
                extractionLog = [extractionLog; extractionRow];
                save(fullfile(extractionLogFile.folder,extractionLogFile.name),'extractionLog');
            case 'csv'
                extractionLog = readtable(fullfile(extractionLogFile.folder,extractionLogFile.name),"Delimiter",',');
                extractionRow_Updt = updateExtractionLog(extractionRow,[],string(extractionLog.Properties.VariableNames),0,0);
                extractionLog = [extractionLog; extractionRow_Updt];                
                writetable(extractionLog,fullfile(extractionLogFile.folder,extractionLogFile.name));
            otherwise
        end           
    end
end