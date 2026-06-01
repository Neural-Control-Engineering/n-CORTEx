function extractionLog = loadExtractionLog(params, extLayer)
    file_extractionLog = sprintf("%s_extraction_log.csv", extLayer);
    path_extractionLog = fullfile(params.paths.expmntPath_cloud,"Extraction-Logs",file_extractionLog);
    extractionLog = readtable(path_extractionLog);
end