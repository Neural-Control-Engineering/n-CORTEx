function dataExtract = extractDataStreams(params, subject, modality)
    % Retrieve a list of unique session names for the animal.
    % [sessionNames] = retrieve_session_list(subject, params.paths, "raw");    
    resetExtraction(params, subject, modality);
    sessions_to_extract = recover4Extraction(params, subject, modality);
    cmd = sprintf("dataExtract = extract%s(params, subject, sessions_to_extract)", modality);
    eval(cmd);    
end