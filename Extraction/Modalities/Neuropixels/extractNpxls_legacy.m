function extractNpxls(params, subject, sessionNames, modality)
    paths = params.paths;
    switch modality
        case "AP"
            % Add the Kilosort parameters path to the MATLAB search path.
            addpath(paths.neuropixel.kilosort_params);
            
            % Check if there are Neuropixel ap data files.
            if ~isempty(dir(fullfile(paths.raw_neuropixel_data, '*Npxl*')))
                
                % Fetch the Neuropixel data sessions to be extracted.
                [spiking_to_process] = recover4Extraction(subject, sessionNames, paths, params.resets.reset_spiking_processing,"AP");
                
                % Process each session of Neuropixel data.
                for session = 1:length(spiking_to_process)
                    ks = [];
                    metrics = [];
                    imec = [];
                    exp_template = spiking_to_process{session}(1:end);
                    % neuropixel_dir = dir(fullfile(paths.raw_neuropixel_data, strcat(exp_template, '*'), strcat(exp_template, '*'), strcat(exp_template, '*')));                        
                    raw_neuropixelSession_dir = dir(fullfile(paths.raw_neuropixel_data, strcat(exp_template, '*'), strcat(exp_template,'_imec*')));
                    % Process each imec in the session
                    for j = 1:length(raw_neuropixelSession_dir)
                        npxlImecDirName = raw_neuropixelSession_dir(j).name;                
                        paths.neuropixel.to_sort = fullfile(raw_neuropixelSession_dir(j).folder,npxlImecDirName);                
                        imecTag = regexp(npxlImecDirName, 'imec(\d+)','tokens','once');
                        imecTag = string(strcat('imec',imecTag));
                        imecBinDir = dir(fullfile(paths.neuropixel.to_sort,"*.bin"));
                        % Process each triggered subset
                        for k = 1:(length(imecBinDir)/2)                                        
                            % Push each triggered subset into a subdir
                            trigNum = k-1;
                            trigPattern = sprintf("_t%d.",trigNum);
                            imecBinSubDir = dataDir(paths.neuropixel.to_sort,trigPattern);
                            trigSubDirFldr = strrep(trigPattern,'_','');
                            trigSubDirFldr = strrep(trigSubDirFldr,'.','');                    
                            destDir = fullfile(paths.ksortNpxlsPath,exp_template,imecTag);
                            if ~isempty(imecBinSubDir)                        
                                copy2SubDir(imecBinSubDir,string(trigSubDirFldr),destDir);
                            end                    
                            
                            %% AP EXTRACTION
                            % Create a Kilosort3 object and run Kilosort on Neuropixel data.                                       
                            imecBinPath = fullfile(destDir,trigSubDirFldr);                    
                            imec = Neuropixel.ImecDataset(imecBinPath);
                            Neuropixel.runKilosort3(imec, paths, exp_template, 'workingdir', fullfile(paths.neuropixel.workingdir,'Temp'));
                            
                            % Save the Kilosort object and compute metrics.                    
                            ks = Neuropixel.KilosortDataset(imecBinPath);
                            ks.load('loadFeatures', false);
                            stats = ks.computeBasicStats();
                            ks.printBasicStats();
                            metrics = ks.computeMetrics();
                            
                            % Plot and save cluster waveforms.
                            figure;
                            metrics.plotClusterWaveformAtCentroid();
                            saveas(gca, fullfile(imecBinPath, "plot-waveforms"), 'fig');
                            
                            % Update the Neuropixel extraction log and save processed data.
                            load(fullfile(paths.all_data_path,"Extraction-Logs", 'spiking_extraction_log.mat'),'extractionLog');
                            save(fullfile(imecBinPath, 'kilosort'), 'ks');
                            save(fullfile(imecBinPath, 'metrics'), 'metrics');
                            extractionLog(contains(extractionLog.Name, spiking_to_process{session, 1}), :).Processed = true;
                            display(strcat("Raw spiking data was processed for ", spiking_to_process{session, 1}));
                            save(fullfile(paths.all_data_path,"Extraction-Logs", 'neuropixel_extraction_log.mat'),'extractionLog');                                
                        end
                    end
                end
            end
        case "LFP"
            extractLFP(params, subject, sessionNames);

            % Check if there are Neuropixel lfp data files.
            if ~isempty(dir(fullfile(paths.raw_neuropixel_data, '*Npxl*')))
                
                % Fetch the Neuropixel lfp data sessions to be extracted.
                [lfp_to_process] = recover4Extraction(subject, sessionNames, paths, params.resets.reset_lfp_processing, "LFP");
                
                % Process each session of Neuropixel lfp data.
                for session = 1:length(lfp_to_process)           
                    exp_template = lfp_to_process{session}(1:end);
                    % neuropixel_dir = dir(fullfile(paths.raw_neuropixel_data, strcat(exp_template, '*'), strcat(exp_template, '*'), strcat(exp_template, '*')));                        
                    raw_neuropixelSession_dir = dir(fullfile(paths.raw_neuropixel_data, strcat(exp_template, '*'), strcat(exp_template,'_imec*')));
                    % Process each imec
                    for j = 1:length(raw_neuropixelSession_dir)
                        npxlImecDirName = raw_neuropixelSession_dir(j).name;                
                        paths.neuropixel.to_sort = fullfile(raw_neuropixelSession_dir(j).folder,npxlImecDirName);                
                        imecTag = regexp(npxlImecDirName, 'imec(\d+)','tokens','once');
                        imecTag = string(strcat('imec',imecTag));
                        imecBinDir = dir(fullfile(paths.neuropixel.to_sort,"*.bin"));
                        % Process each triggered subset
                        for k = 1:(length(imecBinDir)/2)                                        
                            % Relocate each triggered (e.g: '_tX') subset into a subdir
                            trigNum = k-1;
                            trigPattern = sprintf("_t%d.",trigNum);
                            imecBinSubDir = dataDir(paths.neuropixel.to_sort,trigPattern);
                            trigSubDirFldr = strrep(trigPattern,'_','');
                            trigSubDirFldr = strrep(trigSubDirFldr,'.','');                    
                            destDir = fullfile(paths.ksortNpxlsPath,exp_template,imecTag);
                            if ~isempty(imecBinSubDir)                        
                                copy2SubDir(imecBinSubDir,string(trigSubDirFldr),destDir);
                            end                                    
                            params.paths = paths;
                            
                            %% LFP EXTRACTION
                            % LFP = extractLFP(params, lfpToProcess)
                            sglf_LFP = extractLFP(params, lfp_to_process{session});
                            % % Load LFP data and save it.
                            meta_data_to_load = dir(fullfile(path, strcat('*', lfp_to_process{session}, '*lf.bin')));
                            sglx_data_IM_LF = ReadSGLXData(meta_data_to_load.name, meta_data_to_load.folder, chan_imec);
                            % save(fullfile(paths.processed_neuropixel_data, strcat(exp_template, '_LFP'), 'sglx_data_IM_LF'), '-v7.3');                            
        
                            % % Update the Neuropixel extraction log and save processed data.
                            % load(fullfile(paths.raw_neuropixel_data, 'neuropixel_extraction_log.mat'));                    
                            % extractionLog(contains(extractionLog.Name, spiking_to_process{session, 1}), :).Processed = true;
                            % display(strcat("Raw neuropixel data was processed for ", lfp_to_process{session, 1}));
                            % save(fullfile(paths.raw_neuropixel_data, 'neuropixel_extraction_log.mat'),'extractionLog');                                        
                        end
                    end
                end
            end
    end    
end