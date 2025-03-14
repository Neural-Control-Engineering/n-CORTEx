function apExtract = extractAP(q, pq, params, sessions_to_extract)

    modality = params.extractCfg.modality;
    % Check if there are Neuropixel lfp data files.
    localCheck = ~isempty(dir(fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Data","Raw-Data","AP_LFP", '*Npxls*'))); 
    cloudCheck = ~isempty(dir(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","Raw-Data","AP_LFP", '*Npxls*')));
    % params.paths.raw_neuropixel_data = 
    if (localCheck || cloudCheck)

        % load extraction log
        % load(fullfile(params.paths.all_data_path,"Extraction-Logs","AP_extraction_log.mat"),'extractionLog');  
        extractionLog = readtable(fullfile(params.paths.all_data_path,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv",modality)),"Delimiter",",");
        
        % Add Kilosort params path to MATLAB search        
        kilosortParamsPath = fullfile(params.paths.rawData.AP.local,"Kilosort_params");
        params.paths.neuropixel.config = kilosortParamsPath;
        params.paths.neuropixel.kilosort_params = kilosortParamsPath;
        addpath(kilosortParamsPath);      
        setenv("NEUROPIXEL_MAP_FILE",fullfile(params.paths.neuropixel.config,"neuropixPhase3A_kilosortChanMap.mat"))
        setenv("KILOSORT_CONFIG_FILE",fullfile(params.paths.neuropixel.config,"StandardConfig.m"))

        numProbes = params.extractCfg.npxls.numProbes;
        sessions = sessions_to_extract.sessions;
        subjects = sessions_to_extract.subjects;
        cellInit = cell(length(sessions)*500,1);
        
        % Init ap datastore columns
        APCols = {'spike_clusters','spike_amplitude','spike_times','cluster_centroid','cluster_waveform','cluster_ks_label','connected'};
        for i=1:numProbes
            for j = 1:length(APCols)
                % assignin('caller',sprintf("LFP_Npxls%d",i-1),cellInit)
                eval(strcat(sprintf("%s_Npxls%d",APCols{j},i-1),"=cellInit;"));
            end
        end              
        sessionName = cellInit;        
        trialNum = cellInit; 
        subjectName = cellInit;            
        
        % Process each session of Neuropixel lfp data.
        ptr = 0; % accumulation pointer
        for i = 1:length(sessions)   
            ks = [];
            metrics = [];
            imec = [];
            exp_template = sessions{i}(1:end);
            subject = subjects{i};
            exp_template = strrep(exp_template,' ','');
            % get trial mask
            trialMask = extractionLog(contains(extractionLog.SessionName,exp_template),:).TrialMask;
            trialMask = (str2double(split(trialMask,'-'))');
            trialMask = trialMask(~isnan(trialMask));
            % check local and cloud for raw data
            [dataDirs, loc] = scopeRawData(params, exp_template, ["imec","nidq"]);
            nidq_dir = dataDirs.nidq;
            imec_dir = dataDirs.imec;
            if loc.imec
                params.paths.raw_neuropixel_data = params.paths.rawData.(modality).local; 
            else
                params.paths.raw_neuropixel_data = params.paths.rawData.(modality).cloud; 
            end

            

            params.paths.rawData.(modality).nidq = fullfile(nidq_dir(1).folder);
            numImecs = length(imec_dir);                       
            % Process each imec
            for j = 1:numImecs
                imecDirName = imec_dir(j).name;                
                params.paths.rawData.(modality).imec = fullfile(imec_dir(j).folder,imecDirName);                
                imecTag = regexp(imecDirName, 'imec(\d+)','tokens','once');
                imecTag = string(strcat('imec',imecTag));
                imecBinDir = dir(fullfile(params.paths.rawData.(modality).imec,"*lf.bin"));    
                imecTmpDir = fullfile(params.paths.stem,"Temp",modality,"imec");
                nidqTmpDir = fullfile(params.paths.stem,"Temp",modality,"nidq");
                % Process each triggered subset               
                numTrigs = length(imecBinDir);                
                for k = 1:numTrigs                                        
                    if any(ismember(trialMask, k-1))
                        % Relocate each triggered (e.g: '_tX') subset into a subdir 
                        trigNum = k-1;
                        trigPattern = sprintf("_t%d.",trigNum);
                        imecBinSubDir = dataDir(params.paths.rawData.(modality).imec,strcat(trigPattern,imecTag,".ap"));
                        nidqBinSubDir = dataDir(params.paths.rawData.(modality).nidq,strcat(trigPattern,"nidq"));
                        trigSubDirFldr = strrep(trigPattern,'_','');
                        trigSubDirFldr = strrep(trigSubDirFldr,'.','');                    
                        % destDir = fullfile(params.paths.ksortNpxlsPath,"LFP",exp_template,imecTag);
                        
                        if ~isempty(imecBinSubDir); copy2SubDir(imecBinSubDir,string(trigSubDirFldr),imecTmpDir); end
                        copyfile(fullfile(kilosortParamsPath,"chanMap.mat"),fullfile(imecTmpDir,trigSubDirFldr));
                        if ~isempty(nidqBinSubDir); copy2SubDir(nidqBinSubDir,string(trigSubDirFldr),nidqTmpDir); end                                                                                                              
    
                        % AP Extraction
                        % Create a Kilosort3 Object and Run Kilosort on
                        % Neuropixels Data
                        % imecBinPath = fullfile(destDir, trigSubDirFldr);
                        
                        % clear existing kilosort items

                        % trigDir = dir(imecBinPath);
                        % prevOut = trigDir((~contains({trigDir.name},'.bin'))&(~contains({trigDir.name},'.met')));                                     
                        % deleteDir(prevOut);
                        params.paths.ksortNpxlsPath = fullfile(imecTmpDir,trigSubDirFldr);
                        params.paths.neuropixel.to_sort = fullfile(imecTmpDir,trigSubDirFldr);
                        imec = Neuropixel.ImecDataset(params.paths.ksortNpxlsPath);
                        Neuropixel.runKilosort3(imec, params.paths, exp_template, 'workingdir', convertStringsToChars(fullfile(imecTmpDir,trigSubDirFldr)));
        
                        % Save Kilosort Object and compute metrics
                        ks = Neuropixel.KilosortDataset(params.paths.ksortNpxlsPath);
                        ks.load('loadFeatures',false);
                        stats = ks.computeBasicStats();
                        ks.printBasicStats();
                        metrics = ks.computeMetrics();
        
                        % Plot and save cluster waveforms.
                        figure;
                        metrics.plotClusterWaveformAtCentroid();
                        extrctDataPath = fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","Extracted-Data","AP",exp_template,trigSubDirFldr);
                        figPath = fullfile(extrctDataPath,"plot-waveforms");
                        buildPath(figPath);
                        saveas(gca, figPath, 'fig');

                        chan_nidq = 1:9;                                               
                        nidq_meta_data_to_load = dir(fullfile(nidqTmpDir,trigSubDirFldr,strcat('*', sessions{i},'*.nidq.bin')));                        
                        nidq = ReadSGLXData(nidq_meta_data_to_load.name, nidq_meta_data_to_load.folder, chan_nidq); 

                        % Copy kilosort output to drive
                        kSortOut = dir(fullfile(imecTmpDir,trigSubDirFldr));
                        for n = 3 : length(kSortOut)
                            kSortFile = kSortOut(n).name;
                            kSortPath = kSortOut(n).folder;
                            if ~(contains(kSortFile,'bin') || contains(kSortFile,'meta'))
                                copyfile(fullfile(kSortPath,kSortFile),extrctDataPath);
                            end
                        end
        
                        % Write to cell array
                        sessionName{k + ptr} = exp_template;
                        trialNum{k + ptr} = trigNum;       
                        subjectName{k + ptr} = subject;
                        %% CHECK HERE
                        for p = 1:length(APCols)
                            apCol = APCols{p};
                            if apCol == "cluster_ks_label"
                                eval(strcat(sprintf("%s_Npxls%d{k + ptr}",apCol, j-1),sprintf("=ks.%s;",apCol)));
                            elseif apCol == "connected"
                                eval(strcat(sprintf("%s_Npxls%d{k + ptr}",apCol, j-1),sprintf("=metrics.channelMap.%s;",apCol)));
                            else
                                eval(strcat(sprintf("%s_Npxls%d{k + ptr}",apCol, j-1),sprintf("=metrics.%s;",apCol)));
                            end
                        end  
                    end                                                                                  
                end
                if j == numImecs
                    ptr = ptr + numTrigs;
                end
            end  
            
            % log session
            extractionLog(contains(extractionLog.SessionName,exp_template),:).Extracted=1;  
            writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv",modality)));

            % move local raw folder 
            LFPextrctLog = readtable(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs/LFP_extraction_log.csv"),"Delimiter",",");
            lfpIsExtrct = LFPextrctLog(contains(LFPextrctLog.SessionName,exp_template),:).Extracted;
            if lfpIsExtrct
                % move session data to cloud
                % push2Cloud(fullfile(params.paths.rawData.(modality).local,exp_template), fullfile(params.paths.rawData.(modality).cloud));
                if exist(fullfile(params.paths.rawData.(modality).local,exp_template),"dir")
                    copyfile(fullfile(params.paths.rawData.(modality).local,exp_template), fullfile(params.paths.rawData.(modality).cloud,exp_template));                
                    rmdir(fullfile(params.paths.rawData.(modality).local,exp_template),'s');
                end
            end            

            % clear temp
            if exist(imecTmpDir,"dir"); rmdir(imecTmpDir,"s"); end
            if exist(nidqTmpDir,"dir"); rmdir(nidqTmpDir,"s"); end

            % worker progress update
            progress = cell(2,1);
            progress{1} = modality;
            progress{2} = i/length(sessions);
            send(q, 1);
            send(pq, progress);            
            
        end
        
        % save(fullfile(params.paths.all_data_path,"Extraction-Logs","AP_extraction_log.mat"),"extractionLog");  
    
        % save extracted data
        sessionName = cellstr(sessionName(~cellfun('isempty',sessionName)));
        extractLen = length(sessionName);
        % sessionNum = sessionNum(~cellfun('isempty',sessionNum));
        trialNum = cell2mat(trialNum(~cellfun('isempty',trialNum)));   
        subjectName = cellstr(subjectName(~cellfun('isempty',subjectName)));
        
        % Generate ap table
        genTableCmd = 'apTable = table(sessionName, trialNum, subjectName,';        
        for i = 1:numProbes
            for j = 1:length(APCols)
                % remove empty rows
                probeIdx=sprintf("%s_Npxls%d",APCols{j},i-1);
                eval(strcat(probeIdx,'=',probeIdx,"(~cellfun('isempty',",probeIdx,"));"));
                % check if matches sessionNameLen
                eval(sprintf("colLen=length(%s);",probeIdx))
                if colLen == extractLen    
                    % if (i==numProbes && j==length(APCols))
                        % genTableCmd = strcat(genTableCmd,sprintf('%s_Npxls%d);',APCols{j},i-1));                    
                    % else
                    genTableCmd = strcat(genTableCmd,sprintf('%s_Npxls%d, ',APCols{j},i-1));
                    % end        
                end
            end
        end
        genTableCmd=strcat(genTableCmd,');');
        genTableCmd=strrep(genTableCmd,',);',');');
        eval(genTableCmd);
        apExtract = apTable;    
    
    end

    
end