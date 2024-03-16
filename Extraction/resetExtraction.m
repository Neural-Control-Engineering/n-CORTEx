function resetExtraction(params, subjectID, modality)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    extractionLogFname = sprintf("%s_extraction_log.mat",modality);
    
    if params.extractCfg.(modality).reset==true
        % Reset the analysis log
        load(fullfile(params.paths.all_data_path,"Extraction-Logs",extractionLogFname),'extractionLog');
        extractionLog(contains(extractionLog.Name, subjectID),:).Extracted = 0;    
        save(fullfile(params.paths.all_data_path,"Extraction-Logs",extractionLogFname),'extractionLog');
    end
end