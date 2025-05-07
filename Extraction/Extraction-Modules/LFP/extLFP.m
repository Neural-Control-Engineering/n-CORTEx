function LFP = extLFP(SLRT, lfpPath, trigNum)

    % DEFINE
    preBuffLen = 3.5; % pre-trial buffered sample length (seconds)
    postBuffLen = 5.0; % trial segmentation duration (seconds)

    % load sync data (from RAW layer); this should match SLRT and/or externally generated
    % sync data
    load(fullfile(lfpPath,"sync.mat")); % rising edge time vectors and QC meta analysis for cross-device sync pulses
    % load lfp  (from RAW layer)
    load(fullfile(lfpPath,"lfp.mat"));
    try % update: storing metadata from initial RAW extraction
        Fs = lfp.meta.Fs;
        preBuffLen = lfp.meta.preBuffLen;
        lfp = lfp.dataArray;
    catch
        Fs = 500;
        preBuffLen = 3.5;
    end    
    % max_time = SLRT(trigNum,:).("trial-gate_clock_time"){1}(end); % total duration of the session    
    % lfpTime = linspace(-preBuffLen, max(max_time)+preBuffLen, size(lfp,2));
    %% SYNC ALIGNMENT
    % syncOffset = extractSyncOffset(row_SLRT, sync);
    % lfp time vector
    t_lfp = [0:size(lfp,2)-1]./Fs - preBuffLen;

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
            row_SLRT = SLRT(trial,:);            

            % trial-wise temporal offset tracking 
            sync = extractSyncOffset(row_SLRT, sync, [], t_start);            
            offset0 = sync.lines.sync_1Hz.offset0;
            prevSyncOffset = syncOffset; % update prevSyncOffset for next itr
            t_lfp = mapSyncTimeline(lfp, sync.lines.sync_250Hz, offset0);
            % t_lfp = mapSyncTimeline(sync_adj.lines.sync_250Hz,Fs);
            row = table(trial,{session_label},'VariableNames',{'trial_num','session_label'});            
    
            % beginning, end, and stimulus time for trial         
            % start_time = SLRT(trial,:).clock_time{1}(1);
            % fin_time = SLRT(trial,:).clock_time{1}(end);
            start_time = SLRT(trial,:).("trial-gate_clock_time"){1}(1);
            fin_time = SLRT(trial,:).("trial-gate_clock_time"){1}(end);
            
            trial_lfp_inds = find(t_lfp >= (start_time-preBuffLen) & t_lfp <= (fin_time+postBuffLen));       
            % update lfp time vector by offset
            t_lfp = t_lfp + syncOffset;
            % slice lfp signal by trial windows
            try
                lfpSeg = lfp(:,trial_lfp_inds);
                trial_lfpTimes = t_lfp(trial_lfp_inds);
            catch
                lfpSeg = [];
            end                    
            % trial_sync_inds = find(syncTime >= (start_time-preBuffLen) & syncTime <= (fin_time+postBuffLen));           
            row = [row, table({lfpSeg}, {trial_lfpTimes},'VariableNames',{'lfp', 't_lfp'})];
            % store offset
            row = [row, table({syncOffset},'VariableNames',{'syncOffset_lfp'})];
    
            % align lfpTime to events (including sync pulse)
            if ~isempty(lfpSeg)
                for es = 1:length(event_signals)
                        signal = event_signals{es};
                        if ~isnan(SLRT(trial,:).(signal))
                            % event_time = SLRT(trial,:).clock_time{1}(SLRT(trial,:).(signal));
                            event_time = SLRT(trial,:).("trial-gate_clock_time"){1}(SLRT(trial,:).(signal));
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