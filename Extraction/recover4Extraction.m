function [sessions_to_extract] = recover4Extraction(params, subjectID, modality)
%UNTITLED Summary of this function goes here
% Detailed explanation goes here
    % load modality-respective extraction log and return list of sessions
    % not yet extracted
    extractionLogFname = sprintf("%s_extraction_log.mat",modality);
    load(fullfile(params.paths.all_data_path,"Extraction-Logs",extractionLogFname),"extractionLog");
    sessions_to_extract = extractionLog(contains(extractionLog.SessionName,subjectID) & extractionLog.Extracted==0,:);
    sessions_to_extract = string(sessions_to_extract.SessionName);
end