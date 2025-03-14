function extractRAW_PHOTOM(params, sessions_to_extract, Q)
    modality = params.extractCfg.modality;
    % Check if there are Neuropixel lfp data files.
    localCheck = ~isempty(dir(fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Data","RAW","PHOTOM", '*doric*')));
    cloudCheck = ~isempty(dir(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","RAW","PHOTOM", '*doric*')));
    if (localCheck || cloudCheck)
        % Load modality-associated extraction log
        extractionLog = params.extrctItms.RAW.extractionLog;        
        sessions = sessions_to_extract.sessions;
        % subjects = sessions_to_extract.subjects;
        for i = 1 : length(sessions)
            % Find relevant sessions
            exp_template = sessions{i}(1:end);            
            % subject = subjects{i};
            exp_template = strrep(exp_template,' ','');
            sessionLabel = exp_template;
            if sessionExists(params, exp_template, "PHOTOM","RAW")               
                % migrate to cloud
                localPhotomItms = struct2table(dir(fullfile(params.paths.Data.RAW.(modality).local)));
                photomItm = convertCharsToStrings(localPhotomItms(contains(localPhotomItms.name,exp_template),:).name);
                exp_template = photomItm;
                if exist(fullfile(params.paths.Data.RAW.(modality).local,exp_template),"file")
                    copyfile(fullfile(params.paths.Data.RAW.(modality).local,exp_template), strcat("\\?\",fullfile(params.paths.Data.RAW.(modality).cloud,exp_template)));
                    % rmdir(fullfile(params.paths.Data.RAW.(modality).local,exp_template);
                    delete(fullfile(params.paths.Data.RAW.(modality).local,exp_template));
                end
                extractionLog = updateExtractionLog(extractionLog, sessionLabel, "Extracted_photom", 1, 0);
                writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","RAW")));
            end
        end
    end
end