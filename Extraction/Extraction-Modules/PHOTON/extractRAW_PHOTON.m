function extractRAW_PHOTON(params, sessions_to_extract, Q)
    modality = params.extractCfg.modality;
    % Check if there are any folders.
    localCheck = ~isempty(dir(fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Data","RAW","PHOTON")));
    cloudCheck = ~isempty(dir(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","RAW","PHOTON")));
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
            if sessionExists(params, exp_template, "PHOTON","RAW")
                % zip
                localZip = fullfile(params.paths.Data.RAW.PHOTON.local,sessionLabel);
                zip(sprintf("%s.zip",localZip),localZip);      
                % migrate to cloud
                localPhotomItms = struct2table(dir(fullfile(params.paths.Data.RAW.(modality).local)));
                photonItm = convertCharsToStrings(localPhotomItms(contains(localPhotomItms.name,exp_template),:).name);
                exp_template = sprintf("%s.zip",exp_template);
                if isfile(fullfile(params.paths.Data.RAW.(modality).local,exp_template))
                    copyfile(fullfile(params.paths.Data.RAW.(modality).local,exp_template), strcat("\\?\",fullfile(params.paths.Data.RAW.(modality).cloud,exp_template)));
                    % rmdir(fullfile(params.paths.Data.RAW.(modality).local,exp_template);
                    delete(fullfile(params.paths.Data.RAW.(modality).local,exp_template));
                    rmdir(fullfile(params.paths.Data.RAW.(modality).local,strrep(exp_template,".zip","")),"s");
                end
                extractionLog = updateExtractionLog(extractionLog, sessionLabel, "Extracted_photom", 1, 0);
                writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","RAW")));
            end
        end
    end
end