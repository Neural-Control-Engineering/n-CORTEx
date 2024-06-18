function out = extLFP(SLRT, lfpPath)
    
    load(fullfile(lfpPath,"lfp.mat"));
    lfpFs = 500;
    max_time = SLRT(end,:).clock_time{1}(end);        

    events_logical = strcmp(SLRT(1,:).signal_types{1}(:,2), 'event');
    event_signals = SLRT(1,:).signal_types{1}(events_logical,1);
    
    % out = table('Size', [size(SLRT,1),3],  'VariableTypes', {'double', 'cell', 'cell'}, ...
        % 'VariableNames', {'trial_num', 'session_label','lfp'});
    out = [];
    for trial = 1:size(SLRT,1)
        
        % define output table
        session_label = SLRT(trial,:).session_label{1};
        row = table(trial,{session_label},'VariableNames',{'trial_num','session_label'});
        

        % beginning, end, and stimulus time for trial         
        start_time = SLRT(trial,:).clock_time{1}(1);
        fin_time = SLRT(trial,:).clock_time{1}(end);
        lfpTime = [1:1:size(lfp,2)] ./ lfpFs;
        
        trial_lfp_inds = find(lfpTime >= start_time & lfpTime <= fin_time);
        try
            lfpSeg = lfp(:,trial_lfp_inds);
            trial_lfpTimes = lfpTime(trial_lfp_inds);
        catch
            lfpSeg = [];
        end
        row = [row, table({lfpSeg},'VariableNames',{'lfp'})];

        % row = table(cluster_id, {cluster_spike_times}, cluster_quality, {cluster_spike_amplitudes}, ...
        %         cluster_info(c,:).amplitude, {cluster_info(c,:).position}, cluster_info(c,:).contam_pct, ...
        %         {cluster_info(c,:).waveform_class}, {cluster_info(c,:).template}, ...
        %         'VariableNames', {'cluster_id', 'spike_times', 'quality', 'spike_amplitudes', ...
        %         'template_amplitude', 'position', 'contam_pct', 'waveform_class', 'template'});

        % align lfpTime to events
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
end