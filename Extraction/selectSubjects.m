function subjects_to_load = selectSubjects(params)
    % Check if the data source is "Project_Neuromodulation-for-Pain"
    if strcmp(params.paths.data_source, "Project_Neuromodulation-for-Pain")
        % List files in the directory with filenames containing "-Npxl"
        subjAcqs = dir(fullfile(params.paths.raw_neuropixel_data, '*-Npxl*'));        
        % Retrieve project-wise subject names
        subjectLog = readtable(fullfile(params.paths.all_data_path,"subjectLog.csv"));
        subjectNames = {subjectLog.SubjectName};        
       
        %% Create a cell array of unique animal names
        subject_list = string(subjectNames);     
    
        %% Display a dialog box for selecting animals
        [indx, tf] = listdlg('Name', 'File Selection', 'PromptString', {'Select at least one subject you',...
            'would like to run extraction on.'}, ...
            'ListString', subject_list);
        %% Check the response
        switch tf
            case 1
                % Store selected animal names in the output variable
                subjects_to_load = subject_list(indx);
            case ''
                % If no selection is made, return from the function
                return
        end
        
        % Prompt the user to reset neuropixel data processing
        answer_reset_lfp = questdlg('Would you like to re-process extracted lfp data?', ...
            'Reset LFP', ...
            'Yes', 'No', 'Cancel', 'Cancel');
        % Handle the response
        switch answer_reset_lfp
            case 'Yes'
                params.extractCfg.lfp.reset=true;
                % resets.reset_lfp_processing = true;
            case 'No'
                params.extractCfg.lfp.reset=false;                
            case 'Cancel'
                return
            case ''
                return
        end
    end
end