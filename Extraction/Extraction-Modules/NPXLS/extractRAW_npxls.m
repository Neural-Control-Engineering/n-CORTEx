function extractRAW_npxls(params, sessions_to_extract, Q)    
    modality = params.extractCfg.modality;
    npxlsExtract = [];
    % Check if there are Neuropixel lfp data files.
    localCheck = ~isempty(dir(fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Data","Raw-Data","NPXLS", '*Npxls*'))); 
    cloudCheck = ~isempty(dir(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","Raw-Data","NPXLS", '*Npxls*')));
    if (localCheck || cloudCheck)
        % Load modality-associated extraction log
        extractionLog = readtable(fullfile(params.paths.all_data_path,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv",modality)),"Delimiter",",");
        % Add Kilosort params path to MATLAB search        
        kilosortParamsPath = fullfile(params.paths.rawData.NPXLS.local,"Kilosort_params");
        params.paths.neuropixel.config = kilosortParamsPath;
        params.paths.neuropixel.kilosort_params = kilosortParamsPath;
        addpath(kilosortParamsPath);      
        setenv("NEUROPIXEL_MAP_FILE",fullfile(params.paths.neuropixel.config,"neuropixPhase3A_kilosortChanMap.mat"));
        setenv("KILOSORT_CONFIG_FILE",fullfile(params.paths.neuropixel.config,"StandardConfig.m"));        
        % numProbes = params.extractCfg.npxls.numProbes;
        sessions = sessions_to_extract.sessions;
        subjects = sessions_to_extract.subjects;
        for i = 1 : length(sessions)
            % Initialize extraction containers
            ks = [];
            metrics = [];
            imec = [];
            % Find relevant sessions
            exp_template = sessions{i}(1:end);
            subject = subjects{i};
            exp_template = strrep(exp_template,' ','');
            % Get trial mask
            trialMask = extractionLog(contains(extractionLog.SessionName,exp_template),:).TrialMask;
            trialMask = (str2double(split(trialMask,'-'))');
            trialMask = trialMask(~isnan(trialMask));
            % Check local and cloud for raw data
            [dataDirs, loc] = scopeRawData(params, exp_template, ["imec","nidq"]);
            nidq_dir = dataDirs.nidq;
            nidqBinDir = nidq_dir(contains({nidq_dir.name},'.bin'));
            imec_dir = dataDirs.imec;
            if loc.imec
                params.paths.raw_neuropixel_data = params.paths.rawData.(modality).local; 
            else
                params.paths.raw_neuropixel_data = params.paths.rawData.(modality).cloud; 
            end
            % Process each imec
            params.paths.rawData.(modality).nidq = fullfile(nidq_dir(1).folder);
            numImecs = length(imec_dir);                       
            % Process each imec
            for j = 1:numImecs
                imecDirName = imec_dir(j).name;                
                params.paths.rawData.(modality).imec = fullfile(imec_dir(j).folder,imecDirName);                
                imecTag = regexp(imecDirName, 'imec(\d+)','tokens','once');
                imecTag = string(strcat('imec',imecTag));
                imecBinDir_ap = dir(fullfile(params.paths.rawData.(modality).imec,"*ap.bin"));    
                imecBinDir_lfp = dir(fullfile(params.paths.rawData.(modality).imec,"*lf.bin"));    
                % imecTmpDir = fullfile(params.paths.stem,"Temp",modality,"imec");
                % nidqTmpDir = fullfile(params.paths.stem,"Temp",modality,"nidq");
                % Process each triggered subset               
                numTrigs = length(imecBinDir_ap);      
                for k = 1:numTrigs
                    if any(ismember(trialMask, k-1))                       
                        trigNum = k-1;
                        trigPattern = sprintf("_t%d",trigNum);
                        % params.paths.ksortNpxlsPath = fullfile(imecTmpDir,trigSubDirFldr);
                        % params.paths.neuropixel.to_sort = fullfile(imecTmpDir,trigSubDirFldr);                        
                        %% AP
                        % params.paths.ksortNpxlsPath = fullfile(imecBinDir_ap(k).folder,imecBinDir_ap(k).name);
                        params.paths.ksortNpxlsPath = fullfile(imecBinDir_ap(k).folder);
                        params.paths.neuropixel.to_sort = fullfile(imecBinDir_ap(k).folder,imecBinDir_ap(k).name);
                        params.paths.neuropixel.workingdir = fullfile("C:/Temp/NPXLS/");
                        buildPath(params.paths.neuropixel.workingdir);
                        % kilosort output location                        
                        kSortOutFolder = sprintf("%s%s_sorted",exp_template,trigPattern);                        
                        kSortOutPath = fullfile(imecBinDir_ap(k).folder,kSortOutFolder);
                        
                        % % clear previous output 
                        if exist(kSortOutPath,"dir"); rmdir(kSortOutPath,"s"); end
                        buildPath(kSortOutPath);
                        kSortOutPath = strcat("\\?\",kSortOutPath);
                        imec = Neuropixel.ImecDataset(((fullfile(params.paths.ksortNpxlsPath,strcat(exp_template,trigPattern)))));
                        Neuropixel.runKilosort3(imec, params.paths, exp_template, 'workingdir',convertStringsToChars(params.paths.neuropixel.workingdir));
                        % Save Kilosort Object and compute metrics
                        % ks = Neuropixel.KilosortDataset(((fullfile(params.paths.ksortNpxlsPath,strcat(exp_template,trigPattern)))));
                        ks = Neuropixel.KilosortDataset(imec);
                        ks.load('loadFeatures',false);
                        stats = ks.computeBasicStats();
                        ks.printBasicStats();
                        metrics = ks.computeMetrics();    
                        % move output into a subfolder
                        rawNpxlsFolder = dir(fullfile(params.paths.rawData.(modality).imec));
                        for n = 3:length(rawNpxlsFolder)
                            item = rawNpxlsFolder(n).name;
                            loc = rawNpxlsFolder(n).folder;
                            isDir = rawNpxlsFolder(n).isdir;
                            if (~contains(item,'.lf.') && ~contains(item,'.ap.')) && ~isDir
                                movefile(fullfile(loc,item), fullfile(imecBinDir_ap(k).folder,kSortOutFolder));
                            end
                        end    

                        %% LFP
                        % Load LFP data
                        chan_nidq = 1:9;
                        chan_imec = 1:385;
                        % imec_meta_data_to_load = dir(fullfile(imecTmpDir,trigSubDirFldr, strcat('*', sessions{i}, '*lf.bin')));
                        % nidq_meta_data_to_load = dir(fullfile(nidqTmpDir,trigSubDirFldr,strcat('*', sessions{i},'*.nidq.bin')));
                        % fprintf("Extracting %s, trial %d\n", exp_template, trigNum);
                        lfp = ReadSGLXData(imecBinDir_lfp(k).name, imecBinDir_lfp(k).folder, chan_imec);
                        lfp = downsample(lfp.dataArray',5)';
                        nidq = ReadSGLXData(nidqBinDir(k).name, nidqBinDir(k).folder, chan_nidq);
                        
                        save(fullfile(kSortOutPath,"kilosort.mat"),"ks", '-v7.3');                        
                        save(fullfile(kSortOutPath,"metrics.mat"),"metrics");
                        save(fullfile(kSortOutPath,"lfp.mat"),"lfp");
                        save(fullfile(kSortOutPath,"nidq.mat"),"nidq");
                        save(fullfile(kSortOutPath,"stats.mat"),'stats');
                       
                    end
                end
                
                 % migrate to cloud
                if exist(fullfile(params.paths.rawData.(modality).local,exp_template),"dir")
                    copyfile(fullfile(params.paths.rawData.(modality).local,exp_template), strcat("\\?\",fullfile(params.paths.rawData.(modality).cloud,exp_template)));                
                    rmdir(fullfile(params.paths.rawData.(modality).local,exp_template),'s');
                end
                
                % log session
                % extractionLog(contains(extractionLog.SessionName,exp_template),:).Extracted=1;  
                % writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv",modality)));
                % report progress
                % worker progress update
                progress = cell(2,1);
                progress{1} = modality;
                progress{2} = i/length(sessions);
                send(Q.q, 1);
                send(Q.pq, progress);      
            end
        end
    end
end