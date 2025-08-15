function extractRAW_NPXLS(params, sessions_to_extract, Q)    
    cd(fullfile(params.paths.repo_path,"Extraction/"));
    pyVersion = "C:\Users\Primus\anaconda3\envs\kilosort\python.EXE";
    pyenv("Version",pyVersion)
    % modality = params.extractCfg.modality;
    modality = params.extractCfg.modality;    
    % Check if there are Neuropixel lfp data files.
    localCheck = ~isempty(dir(fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Data","RAW","NPXLS", '*Npxls*'))); 
    cloudCheck = ~isempty(dir(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","RAW","NPXLS", '*Npxls*')));
    if (localCheck || cloudCheck)
        % Load modality-associated extraction log
        extractionLog = params.extrctItms.RAW.extractionLog;
        % Add Kilosort params path to MATLAB search        
        kilosortParamsPath = fullfile(params.paths.Data.RAW.NPXLS.local,"Kilosort_params");
        params.paths.neuropixel.config = kilosortParamsPath;
        params.paths.neuropixel.kilosort_params = kilosortParamsPath;
        addpath(kilosortParamsPath);      
        setenv("NEUROPIXEL_MAP_FILE",fullfile(params.paths.neuropixel.config,"neuropixPhase3A_kilosortChanMap.mat"));
        setenv("KILOSORT_CONFIG_FILE",fullfile(params.paths.neuropixel.config,"StandardConfig.m"));        
        % numProbes = params.extractCfg.npxls.numProbes;
        sessions = sessions_to_extract.sessions;
        % subjects = sessions_to_extract.subjects;
        for i = 1 : length(sessions)
            try
                % Find relevant sessions
                exp_template = sessions{i}(1:end);
                % subject = subjects{i};
                exp_template = strrep(exp_template,' ','');
                sessionLabel = exp_template;
                if sessionExists(params, exp_template, "NPXLS","RAW")
                    % Initialize extraction containers
                    ks = [];
                    metrics = [];
                    imec = [];                
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
                        params.paths.raw_neuropixel_data = params.paths.Data.RAW.(modality).local; 
                    else
                        params.paths.raw_neuropixel_data = params.paths.Data.RAW.(modality).cloud; 
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
                        numBins = length(imecBinDir_ap);      
                        for k = 1:numBins
                            bin = imecBinDir_ap(k).name;
                            binFldr = imecBinDir_ap(k).folder;
                            [trigNum, gateNum] = decodeTrigger(bin);
                            if any(ismember(trialMask, trigNum))                       
                                % trigNum = k-1;
                                trigPattern = sprintf("_t%d",trigNum);
                                % params.paths.ksortNpxlsPath = fullfile(imecTmpDir,trigSubDirFldr);
                                % params.paths.neuropixel.to_sort = fullfile(imecTmpDir,trigSubDirFldr);                        
                                %% AP
                                params.paths.ksortNpxlsPath = binFldr;
                                % params.paths.ksortNpxlsPath = fullfile(imecBinDir_ap(k).folder);
                                % params.paths.neuropixel.to_sort = fullfile(imecBinDir_ap(k).folder,imecBinDir_ap(k).name);
                                params.paths.neuropixel.workingdir = fullfile("C:/Temp/NPXLS/");
                                buildPath(params.paths.neuropixel.workingdir);
                                % kilosort output location                        
                                kSortOutFolder = sprintf("%s%s_sorted",exp_template,trigPattern);                        
                                kSortOutPath = fullfile(binFldr,kSortOutFolder);
                                % % clear previous output 
                                if exist(kSortOutPath,"dir"); rmdir(kSortOutPath,"s"); end
                                buildPath(kSortOutPath);
                                % Define the parameters                            
                                data_dir = params.paths.ksortNpxlsPath;
                                fileName = (((fullfile(params.paths.ksortNpxlsPath,strcat(exp_template,trigPattern,'.',imecTag,'.ap.bin')))));
                                chanMap = 'neuropixPhase3A_kilosortChanMap.mat';                            
                                % Import the Python module; Call the function
                                mod = py.importlib.import_module('runKilosort4');
                                results = mod.runKilosort4(data_dir, fileName, chanMap);                            
                                % move output into a subfolder
                                rawNpxlsFolder = dir(fullfile(params.paths.rawData.(modality).imec));
                                for n = 3:length(rawNpxlsFolder)
                                    item = rawNpxlsFolder(n).name;
                                    loc = rawNpxlsFolder(n).folder;
                                    isDir = rawNpxlsFolder(n).isdir;
                                    if strcmp(item,'kilosort4')
                                        movefile(fullfile(loc,item), fullfile(binFldr,kSortOutFolder),'f');
                                    end
                                end    
        
                                %% LFP
                                % Load LFP data
                                chan_nidq = 1:9;
                                chan_imec = 1:385;
                                % Locate Dirs
                                apMetaFileName = strrep(bin,'bin','meta');
                                lfpFileName = strrep(bin,'.ap.bin','.lf.bin');
                                nidqFileName = strrep(bin,'.imec0.ap.bin','.nidq.bin');                            
                                nidqFolder = nidqBinDir(k).folder;
                                lfp = ReadSGLXData(lfpFileName, binFldr, chan_imec);
                                ap = ReadSGLXData(apMetaFileName, binFldr, chan_imec);
                                nidq = ReadSGLXData(nidqFileName,nidqFolder, chan_nidq);                                                                                                                                        
                                % keyboard                            
                                % synch-validation
                                synch1 = nidq.dataArray(9,:); % 1Hz pulser
                                insert1 = nidq.dataArray(2,:); % slrt insert data
                                synch2 = lfp.dataArray(385,:); % 1Hz pulser                            
                                Fs1 = str2double(nidq.meta.niSampRate);
                                Fs2 = str2double(lfp.meta.imSampRate);                            
                                F_synch1 = 1;
                                F_synch2 = 1;
                                args.groupSize = 10;
                                sync.lines.sync_1Hz_nidq=extractSyncLine(synch1,insert1,Fs1,1,"RE-end","world",args.groupSize);
                                sync.lines.sync_1Hz_imec=extractSyncLine(synch2,[],Fs2,1,"RE-end","world",args.groupSize);
                                % [IPD_A, IPD_B, PC_B] = validate_temporalPrecision(synch1, synch2, Fs1, Fs2, F_synch1, F_synch2, args);
                                plot_temporalPrecision(sync.lines.sync_1Hz_imec.IPD, sync.lines.sync_1Hz_nidq.IPD, []);
                                % sync.lines.sync_1Hz.IPD = IPD_A;
                                % sync.lines.sync_1Hz.PC = [];
                                % sync.lines.sync_1Hz.t_RE = IPD_A.t_RE;
                                % sync.lines.sync_250Hz.IPD = IPD_B;
                                % sync.lines.sync_250Hz.PC = PC_B;
                                % sync.lines.sync_250Hz.t_RE = IPD_B.t_RE;
                                %% ANTIALIASING & DOWNSAMPLING
                                % Design the notch filter
                                Fs = str2double(lfp.meta.imSampRate);
                                d = designfilt('bandpassiir', ...
                                            'FilterOrder', 4, ...
                                            'HalfPowerFrequency1', 0.1, ...
                                            'HalfPowerFrequency2', 100, ...
                                            'DesignMethod', 'butter', ...
                                            'SampleRate', Fs);                                                       
                                args_antiAlias.Fs = Fs;
                                args_antiAlias.contextWin = 50;
                                lfp_filt = antiAlias(lfp.dataArray, d, args_antiAlias );
                                downSampleRate=5;
                                lfp_downSample = downsample(lfp_filt',downSampleRate)';   
                                lfp.dataArray = lfp_downSample;
                                lfp.meta.Fs=Fs/downSampleRate;
                                lfp.meta.preBuffLen = 3.5;                            
                                %% SAVE RESULTS                            
                                save(fullfile(strcat("\\?\",kSortOutPath),"lfp.mat"),"lfp");
                                save(fullfile(strcat("\\?\",kSortOutPath),"nidq.mat"),"nidq");                              
                                save(fullfile(strcat("\\?\",kSortOutPath),"sync.mat"),"sync");
                                save(fullfile(strcat("\\?\",kSortOutPath),"ap.mat"),"ap");
                                %% UPDATE UI
                                progress = cell(2,1);
                                progress{1} = modality;                     
                                progress{2} = (i-1)/length(sessions) + k/numBins;
                                send(Q.q, 1);
                                send(Q.pq, progress);     
                               
                            end                      
                        end
                        progress = cell(2,1);
                        progress{1} = modality;
                        % progress{2} = i/length(sessions);
                        progress{2} = 1;
                        send(Q.q, 1);
                        send(Q.pq, progress);                               
                        
                        % log session
                        % extractionLog(contains(extractionLog.SessionName,exp_template),:).Extracted=1;  
                        % writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv",modality)));
                        % report progress
                        % worker progress update
                        
                    end
                    % zip raw data
                    % NIDQ
                    nidqDir = struct2table(dir(nidqFolder));
                    nidqItems = nidqDir(contains(nidqDir.name,"nidq"),:).name;
                    nidqFolder = nidqDir(contains(nidqDir.name,"nidq"),:).folder;
                    nidqItems = cellfun(@(x, fldr) fullfile(fldr,x), nidqItems, nidqFolder, "UniformOutput", false);
                    zip(fullfile(nidqFolder{1},"NIDQ"),nidqItems);
                    cellfun(@(x) delete(x), nidqItems, "UniformOutput",false);
                    % LFP/AP
                    imecDir = struct2table(dir(fullfile(imec_dir.folder,imec_dir.name)));
                    imecItems = imecDir(contains(imecDir.name,"meta") | contains(imecDir.name,"bin"),:).name;
                    imecFolder = imecDir(contains(imecDir.name,"meta") | contains(imecDir.name,"bin"),:).folder;
                    imecItems = cellfun(@(x, fldr) fullfile(fldr,x), imecItems, imecFolder, "UniformOutput", false);
                    zip(fullfile(imecFolder{1},"IMEC"),imecItems);
                    cellfun(@(x) delete(x), imecItems, "UniformOutput",false);
                    % migrate to cloud
                    % DEBUGGING, DECOMMENT HERE
                    if exist(fullfile(params.paths.Data.RAW.(modality).local,exp_template),"dir")
                        copyfile(fullfile(params.paths.Data.RAW.(modality).local,exp_template), strcat("\\?\",fullfile(params.paths.Data.RAW.(modality).cloud,exp_template)));                
                        rmdir(fullfile(params.paths.Data.RAW.(modality).local,exp_template),'s');
                    end
                    extractionLog = updateExtractionLog(extractionLog, sessionLabel, "Extracted_npxls", 1, 0);
                    writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","RAW")));
                end
            catch e
                disp(getReport(e));
            end
        end
    end
    cd(fullfile(params.paths.repo_path));
end
% binFldr=pwd;
% lfp = ReadSGLXData(fileNAme, binFldr, chan_imec);
% nidq = ReadSGLXData(fileNAme, binFldr, chan_nidq);
% slrt250_1K=realtimeLog.data.getElement("sync_250Hz_int").Values.Data;
% figure; plot(slrt250_1K(1:10000)); hold on; plot(npx250_1K(1:10000));
% read ap.bin
