function LFP = extLFP(SLRT, lfpPath, trigNum)

    % DEFINE
    preBuffLen = 3.5; % pre-trial buffered sample length (seconds)
    postBuffLen = 5.0; % trial segmentation duration (seconds)
    kilosort_path = fullfile(lfpPath,"kilosort4");

    % load sync data (from RAW layer); this should match SLRT and/or externally generated
    % sync data
    load(fullfile(lfpPath,"sync.mat")); % rising edge time vectors and QC meta analysis for cross-device sync pulses
    % load lfp  (from RAW layer)
    load(fullfile(lfpPath,"lfp.mat"));
    try % update: storing metadata from initial RAW extraction
        lfpMeta = lfp.meta; % store metadata
        Fs = lfp.meta.Fs;
        preBuffLen = lfp.meta.preBuffLen;
        % lfp = lfp.dataArray;
        firstSample = str2double(lfpMeta.firstSample);
        Fs_original = str2double(lfpMeta.imSampRate);
        t_start = firstSample / Fs_original; % seconds passed until trial-gate started - aligned with trigNum
    catch e
        disp(getReport(e));
        Fs = 500;
        preBuffLen = 3.5;
    end    
    % max_time = SLRT(trigNum,:).("trial-gate_clock_time"){1}(end); % total duration of the session    
    % lfpTime = linspace(-preBuffLen, max(max_time)+preBuffLen, size(lfp,2));
    %% SYNC ALIGNMENT
    % syncOffset = extractSyncOffset(row_SLRT, sync);
    % lfp time vector
    % t_lfp = [0:size(lfp,2)-1]./Fs - preBuffLen;
    sync_ref = constructSync_slrt(SLRT, trigNum);
    %% TEMPORARY PLOT HERE
    sync.lines.sync_1Hz_imec.t_edges = filterSyncEdges(sync.lines.sync_1Hz_imec.t_edges,1/sync.lines.sync_1Hz_imec.Freq);
    sync = extractSyncOffset(sync_ref.lines.sync_1Hz_slrt, sync, t_start);
    fig = figure; plot(sync.lines.sync_1Hz_imec.syncOffsets,"Visible","off");
    saveas(fig, strcat(kilosort_path, '/lfp_temp_drift.fig'))
    close(fig);
    % visualize offsets
    % plotSyncOffsets_postProc(sync.lines.sync_1Hz_nidq, sync_ref.lines.sync_1Hz_slrt, sessionDetails);
    % t_lfp = mapSyncTimeline(ap, sync.lines.sync_1Hz_imec, sync.lines.sync_1Hz_imec.offset0);
    t_lfp = mapSyncTimeline(lfp, sync.lines.sync_1Hz_imec, sync.lines.sync_1Hz_imec.offset0);
    % t_lfp = mapSyncTimeline(lfp, sync.lines.sync_1Hz_imec, offset0_imec);

    events_logical = strcmp(SLRT(1,:).signal_types{1}(:,2), 'event');
    event_signals = SLRT(1,:).signal_types{1}(events_logical,1);
    
    % out = table('Size', [size(SLRT,1),3],  'VariableTypes', {'double', 'cell', 'cell'}, ...
        % 'VariableNames', {'trial_num', 'session_label','lfp'});
    out = [];
    prevSyncOffset = []; % initialize empty syncOffset for recursive offset finding (extractSyncOffset)
    for trial = 1:size(SLRT,1)
        % only apply to SLRT trials matching trigNum
        trialGate = SLRT(trial,:).("trial-gate"){1}; % find which acquisition gate
        if trialGate == trigNum
            % define output table
            session_label = SLRT(trial,:).session_label{1};
            % row_SLRT = SLRT(trial,:);            
            % trial-wise temporal offset tracking 
            % sync = extractSyncOffset(row_SLRT, sync, [], t_start);            
            % offset0_nidq = sync.lines.sync_1Hz_nidq.offset0;
            % offset0_imec = sync.lines.sync_1Hz_imec.offset0;
            % prevSyncOffset = syncOffset; % update prevSyncOffset for next itr            
            % t_lfp = mapSyncTimeline(sync_adj.lines.sync_250Hz,Fs);
            % t_lfp = mapSyncTimeline(lfp, sync.lines.sync_1Hz_imec, offset0_imec);
                  
            % beginning, end, and stimulus time for trial         
            % start_time = SLRT(trial,:).clock_time{1}(1);
            % fin_time = SLRT(trial,:).clock_time{1}(end);
            t_start = SLRT(trial,:).("trial-gate_clock_time"){1}(1);
            t_stop = SLRT(trial,:).("trial-gate_clock_time"){1}(end);
            
            trial_lfp_inds = find(t_lfp >= (t_start-preBuffLen) & t_lfp <= (t_stop+postBuffLen));                   
            % slice lfp signal by trial windows
            try
                lfpSeg = lfp.dataArray(:,trial_lfp_inds);
                trial_lfpTimes = t_lfp(trial_lfp_inds);
            catch
                lfpSeg = [];
            end                    
            % row = table(trial,{session_label},'VariableNames',{'trial_num','session_label'});        
            row = table(trialGate,{session_label},'VariableNames',{'trial_num','session_label'});        
            % trial_sync_inds = find(syncTime >= (start_time-preBuffLen) & syncTime <= (fin_time+postBuffLen));           
            lfp_chans = (1:size(lfpSeg,1))';
            row = [row, table({lfpSeg}, {trial_lfpTimes}, {lfp_chans}, ...
                              'VariableNames', {'lfp_df','lfp_t','lfp_chans'})];
            % store offset
            row = [row, table({sync},'VariableNames',{'sync_SGL'})];
    
            % align lfpTime to events (including sync pulse)
            if ~isempty(lfpSeg)
                for es = 1:length(event_signals)
                        signal = event_signals{es};
                        eventData = SLRT(trial,:).(signal);
                        switch class(eventData)
                            case 'cell'
                                eventData=eventData{1};                            
                        end
                        if ~isnan(eventData)
                            % event_time = SLRT(trial,:).clock_time{1}(SLRT(trial,:).(signal));
                            event_time = SLRT(trial,:).("trial-gate_clock_time"){1}(eventData);
                            aligned_lfpTime = trial_lfpTimes - event_time;
                        else
                            aligned_lfpTime = [];
                        end                    
                        row = [row, table({aligned_lfpTime}, 'VariableNames', {strcat(signal,'_aligned_lfp_time')})];
                end                                  
            else        
                for es = 1:length(event_signals)
                        signal = event_signals{es};                    
                        aligned_lfpTime = [];                
                        row = [row, table({aligned_lfpTime}, 'VariableNames', {strcat(signal,'_aligned_lfp_time')})];
                end  
            end
            
            if trial == 1
                out = row;
            else
                out = [out; row];
            end              
        end
    end

    LFP = out;
end