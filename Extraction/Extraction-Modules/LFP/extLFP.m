function LFP = extLFP(SLRT, lfpPath, trigNum)

    % DEFINE
    preBuffLen = 3.5; % pre-trial buffered sample length (seconds)
    postBuffLen = 5.0; % trial segmentation duration (seconds)

    % load sync data (from RAW layer); this should match SLRT and/or externally generated
    % sync data
    load(fullfile(lfpPath,"sync.mat")); % rising edge time vectors and QC meta analysis for cross-device sync pulses
    % load lfp  (from RAW layer)
    load(fullfile(lfpPath,"lfp.mat"));
    lfpFs = 500;
    max_time = SLRT(end,:).clock_time{1}(end); % total duration of the session
    lfpTime = linspace(-preBuffLen, max(max_time)+preBuffLen, size(lfp,2));

    events_logical = strcmp(SLRT(1,:).signal_types{1}(:,2), 'event');
    event_signals = SLRT(1,:).signal_types{1}(events_logical,1);
    
    % out = table('Size', [size(SLRT,1),3],  'VariableTypes', {'double', 'cell', 'cell'}, ...
        % 'VariableNames', {'trial_num', 'session_label','lfp'});
    out = [];
    for trial = 1:size(SLRT,1)

        % only apply to SLRT trials matching trigNum
        
        % define output table
        session_label = SLRT(trial,:).session_label{1};
        row = table(trial,{session_label},'VariableNames',{'trial_num','session_label'});
        

        % beginning, end, and stimulus time for trial         
        start_time = SLRT(trial,:).clock_time{1}(1);
        fin_time = SLRT(trial,:).clock_time{1}(end);
        
        trial_lfp_inds = find(lfpTime >= (start_time-preBuffLen) & lfpTime <= (fin_time+postBuffLen));       
        % slice lfp signal by trial windows
        try
            lfpSeg = lfp(:,trial_lfp_inds);
            trial_lfpTimes = lfpTime(trial_lfp_inds);
        catch
            lfpSeg = [];
        end
        % slice sync lines by trial windows
        syncID = "";
        trial_sync_inds = find(syncTime >= (start_time-preBuffLen) & syncTime <= (fin_time+postBuffLen));
        try
            syncSeg = sync.lines.(syncID);
        catch
            syncSeg = [];
        end
        row = [row, table({lfpSeg}, {trial_lfpTimes},'VariableNames',{'lfp', 'lfpTime'})];
        
        % row = [row, table({syncSeg},'VariableNames',{sprintf('sync_%d',F_synch)})];

        % align lfpTime to events (including sync pulse)
        if ~isempty(lfpSeg)
            for es = 1:length(event_signals)
                    signal = event_signals{es};
                    if ~isnan(SLRT(trial,:).(signal))
                        event_time = SLRT(trial,:).clock_time{1}(SLRT(trial,:).(signal));
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

    LFP = out;
end