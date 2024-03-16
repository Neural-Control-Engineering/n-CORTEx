function JOLTExtract = extractJOLT(params, sessions_to_extract)
    % function to return npxls acquisition times 
    % relative to user action (e.g. Button presses)
    JOLTExtract = [];
    % Check if there are realtime data files.
    if ~isempty(dir(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","Raw-Data","SLRT")))        
        
        % Fetch the Neuropixel data sessions to be extracted.
        % params.extractCfg.reset = params.extractCfg.behavior.slrt.reset;
        % [sessions_to_extract] = recover4Extraction(params, subject, sessionNames, "SLRT");
        lenRTSessions = length(sessions_to_extract);
        
        % initiate Datastore cells
        cellInit = cell(lenRTSessions,1);
        subjectName = cellInit;
        sessionName = cellInit;
        trialNum = cellInit;
        date = cellInit;
        responseDelay = cellInit;
        responseThreshold = cellInit;
        stimTrace_filt = cellInit;
        stimTrace_raw = cellInit;
        % stimTrace_raw = cellInit;
        pawSide = cellInit;
        
        % treatmentDeliv = cellInit;

        % Loop through each behavior trial and build database cols
        ptr = 0;
        subjects = sessions_to_extract.subjects;
        sessions = sessions_to_extract.sessions;
        for i = 1:length(sessions)
            exp_template = sessions{i}(1:end);
            exp_template = strrep(exp_template,".mat",'');
            subject = subjects{i};
            % load session realtime log data
            rtSession = sessions(i);
            rtData = load(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","Raw-Data","SLRT",rtSession));                                             
            rtData = rtData.realtimeLog.data;                

            % load stim trace                           
            stim_filt = get(rtData,"stim_filt");
            stim_filt = stim_filt.Values;
            stim_raw = get(rtData,"stim_raw");
            stim_raw = stim_raw.Values;
            
            % acquisition timing
            acqPulse = get(rtData,"npxlsAcq_out");
            acqPulse = acqPulse{1}.Values;
            acqStarts = diff(acqPulse.Data);
            riseIdx = find(acqStarts>0)+1;
            cutoff = find(rtData,"npxlsAcqCutoff");
            if ~isempty(cutoff)
                cutoff = cutoff.Values;
                cut = diff(cutoff.Data);
                fallIdx = find(cut>0)+1;
            else
                fallIdx = find(acqStarts<0)+1;
            end                    
            riseTimes = acqPulse.Time(riseIdx);                    
            fallTimes = acqPulse.Time(fallIdx);

            % keep/discard status
            trialStat = get(rtData, "buttonStat");
            trialStat = trialStat.Values;
            % trialStart = find(diff(trialStat.Data) == 1) + 1;
            trialKeepOrDrop_idx = find(diff(trialStat.Data) > 1) + 1;
            trialKeepOrDrop = trialStat.Data(trialKeepOrDrop_idx);
            % trialDiscard = find(diff(trialStat.Data) == 3) + 1;

            % sample rate calcs
            stimPreBuff_nSamp = 0.500 * 1/(acqPulse.Time(2) - acqPulse.Time(1));            

            numTrials = length(riseTimes);
    
            % loop through each trial and return metrics
            m = 1;
            n = 1;
            trialMask=[];
            for j=1:numTrials                
                if regexp(rtSession, 'spontaneous', 'match', 'once') == "spontaneous"
                    % write results
                    trialMask = [trialMask, 0];
                    responseThreshold{ptr+n} = nan;
                    responseDelay{ptr+n} = nan;
                    stimTrace_filt{ptr+n} = nan;
                    stimTrace_raw{ptr+n} = nan;
                    subjectName{ptr+n} = subject;
                    sessionName{ptr+n} = exp_template;
                    trialNum{ptr+n} = 0;
                    rtSessionParts = split(rtSession,"_");
                    date{ptr+n} = rtSessionParts(1);
                    pawSide{ptr+n} = 'spontaneous';
                    n=n+1;
                elseif trialKeepOrDrop(j) == 2
                    trialMask = [trialMask, j-1];
                    % rise/fall indexing
                    t_rise = riseTimes(j);
                    idx_rise = find(acqPulse.Time==t_rise);
                    t_fall = fallTimes(j);
                    idx_fall = find(acqPulse.Time==t_fall);
    
                    % isolate stim waveform
                    stimFiltTrial = stim_filt.Data(idx_rise:idx_fall);                
                    stimFiltTrial_time = stim_filt.Time(idx_rise:idx_fall);
                    % stimRawTrial = stim_raw.Data(idx_rise:idx_fall);
                    % stimRawTrial_time = stim_raw.Data(idx_rise:idx_fall);
                    idx_peakFilt = find(stimFiltTrial == max(stimFiltTrial));                           
                    t_peak = stimFiltTrial_time(idx_peakFilt);
    
                    % write results
                    responseThreshold{ptr+n} = stimFiltTrial(idx_peakFilt);
                    responseDelay{ptr+n} = t_peak - t_rise;
                    stimTrace_filt{ptr+n} = stim_filt.Data(idx_rise-stimPreBuff_nSamp:idx_fall);
                    stimTrace_raw{ptr+n} = stim_raw.Data(idx_rise-stimPreBuff_nSamp:idx_fall);
                    subjectName{ptr+n} = subject;
                    sessionName{ptr+n} = exp_template;
                    trialNum{ptr+n} = j-1;
                    rtSessionParts = split(rtSession,"_");
                    date{ptr+n} = rtSessionParts(1);
                    paw = regexp(rtSession, '([LR])-hind-paw', 'match', 'once');
                    paw = string(paw);
                    switch paw
                        case 'L-hind-paw'
                            pawSide{ptr+n} = 'L';
                        case 'R-hind-paw'
                            pawSide{ptr+n} = 'R';
                        otherwise
                            pawSide{ptr+n} = nan;
                    end
                    n=n+1;
                    m=m+1;
                end                        
            end
            ptr = ptr + numTrials;                           
            
            % log extracted session
            % load(fullfile(params.paths.all_data_path,"Extraction-Logs","SLRT_extraction_log.mat"),'extractionLog');
            extractionLog = readtable(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs","SLRT_extraction_log.csv"),"Delimiter",",");
            extractionLog(contains(extractionLog.SessionName,exp_template),:).Extracted = 1;
            % save(fullfile(params.paths.all_data_path,"Extraction-Logs","SLRT_extraction_log.mat"),'extractionLog');
            writetable(extractionLog,fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs","SLRT_extraction_log.csv"));
            % write 'accepted trial' mask to all other extraction logs
            formatString = repmat('%d ', size(trialMask,1), size(trialMask,2));
            disp(trialMask);
            disp(exp_template);
            trialMask = string(compose(formatString,trialMask));
            trialMask = strrep(trialMask," ","-");
            write2Extrctn(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs"),exp_template,'TrialMask',trialMask);

            progress = cell(2,1);
            progress{1} = "JOLT";
            progress{2} = i/length(sessions);
            send(pq, progress);
            send(q,1);
        end
        sessionName = cellstr(sessionName(~cellfun('isempty',sessionName)))';
        trialNum = cell2mat(trialNum(~cellfun('isempty',trialNum)))';
        subjectName = cellstr(subjectName(~cellfun('isempty',subjectName)))';
        pawSide = pawSide(~cellfun('isempty',pawSide))';
        date = date(~cellfun('isempty',date))';
        responseDelay = responseDelay(~cellfun('isempty',responseDelay))';
        responseThreshold = responseThreshold(~cellfun('isempty',responseThreshold))';
        stimTrace_filt = stimTrace_filt(~cellfun('isempty',stimTrace_filt))';
        stimTrace_raw = stimTrace_raw(~cellfun('isempty',stimTrace_raw))';

        JOLTExtract = table(sessionName, trialNum, subjectName, pawSide, date, responseDelay, responseThreshold, stimTrace_filt, stimTrace_raw);   
        % JOLTExtract = JOLTExtract(~cellfun('isempty',JOLTExtract.sessionName),:);
    end
end