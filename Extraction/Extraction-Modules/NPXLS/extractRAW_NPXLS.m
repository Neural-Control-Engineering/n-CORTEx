function extractRAW_NPXLS(params, sessions_to_extract, Q)    
    cd(fullfile(params.paths.repo_path,"Extraction/"));
    % pyVersion = "C:\Users\Primus\anaconda3\envs\kilosort\python.EXE";
    pyVersion = "C:\Users\Primus\miniconda3\envs\nexus\python.EXE";
    pyenv(Version=pyVersion,ExecutionMode="OutOfProcess");
    % pyenv(Version=pyVersion);
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
        % Keep the RTX 5070 out of deep idle for the whole extraction run: it sits
        % in a chipset PCIe x4 slot and otherwise falls off the bus during the GPU-
        % idle gaps between per-trigger subprocesses (zip/cloud-copy/LFP), causing a
        % TDR / hard hang. Started here; onCleanup stops it on ANY exit (incl.
        % error). See Extraction/GPUKeepAlive/README.md.
        pacifierPy  = fullfile(params.paths.repo_path,"Extraction","GPUKeepAlive","gpu_pacifier.py");
        pacifierLog = fullfile("C:\Users\Primus\gpu-tdr-diag","pacifier.out.log");
        system(sprintf('start "gpu_pacifier" /B "%s" "%s" > "%s" 2>&1', pyVersion, pacifierPy, pacifierLog));
        stopPacifier = onCleanup(@() system(sprintf('"%s" "%s" --stop', pyVersion, pacifierPy))); %#ok<NASGU>
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
                    % try
                    params.paths.rawData.(modality).nidq = fullfile(nidq_dir(1).folder);
                    % catch
                        % keyboard
                    % end
                    numImecs = length(imec_dir);

                    % Resolve subjectDir once per session — same for all j/k
                    subjectDir = '';
                    try
                        subjID     = char(parseSessionLabel(sessionLabel, 'subj'));
                        subjectDir = fullfile(params.paths.projDir_cloud, "Experiments", ...
                            params.extractCfg.experiment, "Subjects", subjID);
                        if ~isfolder(subjectDir)
                            subjectDir = fullfile(params.paths.projDir_local, "Experiments", ...
                                params.extractCfg.experiment, "Subjects", subjID);
                        end
                    catch e_subj
                        fprintf('[atlas] subjectDir: %s\n', e_subj.message);
                    end
                    spk_ks_list = {}; bins_ks_list = {};
                    spk_rt_list = {}; bins_rt_list = {};

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
                                % Run Kilosort4 in a clean subprocess (nexus env).
                                % Embedding via py.* fails: the nexus env's pyexpat
                                % links an external libexpat.dll that collides with
                                % MATLAB's own libexpat.dll in-process. A subprocess
                                % has none of MATLAB's DLLs loaded. Results are written
                                % to the kilosort4 output folder on disk (moved below).
                                ksScript = fullfile(params.paths.repo_path,"Extraction","runKilosort4.py");
                                ksCmd = sprintf('"%s" "%s" "%s" "%s" "%s"', pyVersion, ksScript, data_dir, fileName, chanMap);
                                [ksStatus, ksOut] = system(ksCmd);
                                if ksStatus ~= 0
                                    error("extractRAW_NPXLS:kilosortFailed", ...
                                        "Kilosort4 subprocess failed (exit %d):\n%s", ksStatus, ksOut);
                                end
                                % --- Legacy embedded call (revert to this if needed) ---
                                % mod = py.importlib.import_module('runKilosort4');
                                % results = mod.runKilosort4(data_dir, fileName, chanMap);
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
                                %% COLLECT KS4 — atlas + UnitMatch written once after all triggers
                                try
                                    ks4Dir = fullfile(kSortOutPath, 'kilosort4');
                                    spk_ks_list{end+1}  = loadKS4_spk(ks4Dir);
                                    bins_ks_list{end+1} = char(fileName);
                                catch e_ks
                                    fprintf('[atlas/KS] collect %s t%d: %s\n', sessionLabel, trigNum, e_ks.message);
                                end

                                %% RTSORT OPTIONAL
                                rtsArgs = extractMethodCfg('extractRAW_rtSort');
                                % Prefer a pre-trained sorter for this session (e.g. a
                                % 30 s-context model saved under the experiment's npxls
                                % module folder) over learning one from this short
                                % trigger; "" → runRTSort.py detects as before.
                                rtsArgs.sorterPickle = resolveRTSortPickle(params, sessionLabel);
                                extractRAW_rtSort(fileName, kSortOutPath, [], rtsArgs);

                                %% COLLECT RTSORT — atlas + UnitMatch written once after all triggers
                                try
                                    rtsPath = fullfile(kSortOutPath, 'rtsort_results.mat');
                                    if isfile(rtsPath)
                                        spk_rt_list{end+1}  = loadRTSort_spk(rtsPath);
                                        bins_rt_list{end+1} = char(fileName);
                                    end
                                catch e_rt
                                    fprintf('[atlas/RT] collect %s t%d: %s\n', sessionLabel, trigNum, e_rt.message);
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
                                sync.lines.sync_1Hz_nidq=extractSyncLine(synch1,insert1,Fs1,1,"RE-end","world",args.groupSize,0,0);
                                sync.lines.sync_1Hz_imec=extractSyncLine(synch2,[],Fs2,1,"RE-end","world",args.groupSize,0,0);
                                % [IPD_A, IPD_B, PC_B] = validate_temporalPrecision(synch1, synch2, Fs1, Fs2, F_synch1, F_synch2, args);
                                try
                                    plot_temporalPrecision(sync.lines.sync_1Hz_imec.IPD, sync.lines.sync_1Hz_nidq.IPD, []);
                                catch e
                                    disp(getReport(e));
                                end
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
                    %% WRITE UNITMATCH + REGISTER ATLAS — once per session, all triggers pooled
                    if ~isempty(subjectDir)
                        if ~isempty(spk_ks_list)
                            try  % UnitMatch waveforms — independent of atlas
                                nexAtlas_writePreparedData(spk_ks_list, bins_ks_list, sessionLabel, subjectDir, 'KS');
                            catch e_wf
                                fprintf('[atlas/KS/UnitMatch] %s: %s\n', sessionLabel, e_wf.message);
                                rethrow(e_wf);
                            end
                            try  % Atlas registration — always runs regardless of UnitMatch outcome
                                spk_mg = mergeSpkList_public(spk_ks_list);
                                [DF_tmpl, DF_spat, DF_isi] = nexAtlas_spkToDFs(spk_mg);
                                nexAtlas_registerSession(subjectDir, sessionLabel, DF_tmpl, ...
                                    struct('DF_spatial', DF_spat, 'DF_isi', DF_isi, ...
                                           'sorterTag', 'KS', 'fs', spk_mg.fs));
                            catch e_atlas
                                fprintf('[atlas/KS] %s: %s\n', sessionLabel, e_atlas.message);
                                rethrow(e_atlas);
                            end
                        end
                        if ~isempty(spk_rt_list)
                            try  % UnitMatch waveforms
                                nexAtlas_writePreparedData(spk_rt_list, bins_rt_list, sessionLabel, subjectDir, 'RT');
                            catch e_wf
                                fprintf('[atlas/RT/UnitMatch] %s: %s\n', sessionLabel, e_wf.message);
                                rethrow(e_wf);
                            end
                            try  % Atlas registration
                                spk_mg = mergeSpkList_public(spk_rt_list);
                                [DF_tmpl, DF_spat, DF_isi] = nexAtlas_spkToDFs(spk_mg);
                                nexAtlas_registerSession(subjectDir, sessionLabel, DF_tmpl, ...
                                    struct('DF_spatial', DF_spat, 'DF_isi', DF_isi, ...
                                           'sorterTag', 'RT', 'fs', spk_mg.fs));
                            catch e_atlas
                                fprintf('[atlas/RT] %s: %s\n', sessionLabel, e_atlas.message);
                                rethrow(e_atlas);
                            end
                        end
                    end

                    % compress raw data (LZMA2 level 1, multithreaded)
                    sevenZip = 'C:\Program Files\7-Zip\7z.exe';
                    % NIDQ
                    nidqDir = struct2table(dir(nidqFolder));
                    nidqItems = nidqDir(contains(nidqDir.name,"nidq"),:).name;
                    nidqFolder = nidqDir(contains(nidqDir.name,"nidq"),:).folder;
                    nidqItems = cellfun(@(x, fldr) fullfile(fldr,x), nidqItems, nidqFolder, "UniformOutput", false);
                    sevenZipArchive(sevenZip, fullfile(nidqFolder{1},"NIDQ.7z"), nidqItems);
                    % zip(fullfile(nidqFolder{1},"NIDQ"),nidqItems);
                    % cellfun(@(x) delete(x), nidqItems, "UniformOutput",false);
                    % LFP/AP — one archive per probe
                    % imecDir = struct2table(dir(fullfile(imec_dir.folder,imec_dir.name)));
                    % imecItems = imecDir(contains(imecDir.name,"meta") | contains(imecDir.name,"bin"),:).name;
                    % imecFolder = imecDir(contains(imecDir.name,"meta") | contains(imecDir.name,"bin"),:).folder;
                    % imecItems = cellfun(@(x, fldr) fullfile(fldr,x), imecItems, imecFolder, "UniformOutput", false);
                    % sevenZipArchive(sevenZip, fullfile(imecFolder{1},"IMEC.7z"), imecItems);
                    for ji = 1:numImecs
                        imecDirTbl  = struct2table(dir(fullfile(imec_dir(ji).folder, imec_dir(ji).name)));
                        imecMask    = contains(imecDirTbl.name,"meta") | contains(imecDirTbl.name,"bin");
                        imecItems   = imecDirTbl(imecMask,:).name;
                        imecFolders = imecDirTbl(imecMask,:).folder;
                        imecItems   = cellfun(@(x,fldr) fullfile(fldr,x), imecItems, imecFolders, "UniformOutput", false);
                        imecTagJ    = regexp(imec_dir(ji).name, 'imec(\d+)', 'tokens', 'once');
                        sevenZipArchive(sevenZip, fullfile(imecFolders{1}, sprintf("IMEC%s.7z", imecTagJ{1})), imecItems);
                    end
                    % sevenZipExtract(sevenZip,"C:\NCORTE~1\PROJEC~1\EXPERI~1\JOLT\Data\RAW\NPXLS\DAE573~1\DATE--~1\IMEC0.7z");
                    % zip(fullfile(imecFolder{1},"IMEC"),imecItems);
                    % cellfun(@(x) delete(x), imecItems, "UniformOutput",false);
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

function spk = mergeSpkList_public(spk_list)
% Concatenate spike-level fields across triggers.
% Per-unit metadata is unioned so units appearing only in later triggers
% are not dropped from the merged struct.
    spk = spk_list{1};
    for t = 2:numel(spk_list)
        s = spk_list{t};
        spk.spike_times_s    = [spk.spike_times_s(:);    s.spike_times_s(:)];
        spk.spike_clusters   = [spk.spike_clusters(:);   s.spike_clusters(:)];
        spk.spike_amplitudes = [spk.spike_amplitudes(:); s.spike_amplitudes(:)];
        new_mask = ~ismember(s.unit_ids, spk.unit_ids);
        if any(new_mask)
            new_pos  = find(new_mask);   % rank positions in s of the new units
            spk.unit_ids         = [spk.unit_ids(:);         s.unit_ids(new_mask)];
            spk.unit_locs        = [spk.unit_locs;           s.unit_locs(new_mask, :)];
            spk.unit_quality     = [spk.unit_quality(:);     s.unit_quality(new_mask)];
            spk.unit_root_elecs  = [spk.unit_root_elecs(:);  s.unit_root_elecs(new_mask)];
            % unit_templates / spatial_profiles may have fewer rows than unit_ids
            % (KS4 stores templates only for units passing a higher quality bar).
            % Use position-based indexing with zero-fill for any out-of-bounds units.
            valid_t  = new_pos(new_pos <= size(s.unit_templates,   1));
            n_fill   = numel(new_pos) - numel(valid_t);
            spk.unit_templates   = cat(1, spk.unit_templates, ...
                s.unit_templates(valid_t, :, :), ...
                zeros(n_fill, size(spk.unit_templates,2),   size(spk.unit_templates,3),   'like', spk.unit_templates));
            valid_s  = new_pos(new_pos <= size(s.spatial_profiles, 1));
            n_fill   = numel(new_pos) - numel(valid_s);
            spk.spatial_profiles = [spk.spatial_profiles; ...
                s.spatial_profiles(valid_s, :); ...
                zeros(n_fill, size(spk.spatial_profiles,2), 'like', spk.spatial_profiles)];
        end
    end
end

% binFldr=pwd;
% lfp = ReadSGLXData(fileNAme, binFldr, chan_imec);
% nidq = ReadSGLXData(fileNAme, binFldr, chan_nidq);
% slrt250_1K=realtimeLog.data.getElement("sync_250Hz_int").Values.Data;
% figure; plot(slrt250_1K(1:10000)); hold on; plot(npx250_1K(1:10000));
% read ap.bin
