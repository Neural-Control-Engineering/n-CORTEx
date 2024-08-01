function out = alignSignals2Events(slrt_data)
    signal_types = slrt_data(1,:).signal_types{1};
    signal_inds = find(strcmp(signal_types(:,2), 'signal'));
    event_inds = find(strcmp(signal_types(:,2), 'event'));
    out = slrt_data;
    for s = 1:length(signal_inds)
        sind = signal_inds(s);
        signal_name = signal_types{sind,1};
        % disp(signal_name);
        for e = 1:length(event_inds)
            event_name = signal_types{event_inds(e),1};
            aligned_signals = cell(size(slrt_data,1), 1);
            aligned_times = cell(size(slrt_data,1), 1);
            for t = 1:size(slrt_data,1)
                % disp(t);
                event_ind = slrt_data(t,:).(event_name);
                if ~isnan(event_ind)
                    event_time = slrt_data(t,:).clock_time{1}(event_ind);
                    if t < size(slrt_data,1) && t > 1
                        peri_time = [slrt_data(t-1,:).clock_time{1}; slrt_data(t,:).clock_time{1}; slrt_data(t+1,:).clock_time{1}] - event_time;
                        peri_signal = [slrt_data(t-1,:).(signal_name){1}; slrt_data(t,:).(signal_name){1}; slrt_data(t+1,:).(signal_name){1}];
                    elseif t == 1
                        peri_time = [slrt_data(t,:).clock_time{1}; slrt_data(t+1,:).clock_time{1}] - event_time;
                        peri_signal = [slrt_data(t,:).(signal_name){1}; slrt_data(t+1,:).(signal_name){1}];
                    else
                        peri_time = [slrt_data(t-1,:).clock_time{1}; slrt_data(t,:).clock_time{1}] - event_time;
                        peri_signal = [slrt_data(t-1,:).(signal_name){1}; slrt_data(t,:).(signal_name){1}];
                    end
                    aligned_signal = peri_signal(peri_time >= -3.5 & peri_time <= 5.0);
                    aligned_time = peri_time(peri_time >= -3.5 & peri_time <= 5.0);
                    aligned_signals{t} = aligned_signal;
                    aligned_times{t} = aligned_time;
                end
            end
            col_title = strcat(event_name, '_aligned_', signal_name);
            tCol_title = strcat(event_name, '_aligned_', signal_name,'_time');
            out = [out, table(aligned_signals, 'VariableNames', {col_title})];
            out = [out, table(aligned_times, 'VariableNames', {tCol_title})];
        end
    end