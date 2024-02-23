function extract = extraction(params, modality, subjectsToLoad)
    % loop through all selected subjects and extract data for given
    % modality      
    for subjectNum = 1:length(subjectsToLoad)
        % Run through all files and find unprocessed data    
        subject = subjectsToLoad{subjectNum};
        extract = extractDataStreams(params, subject, modality);                        
    end   
end