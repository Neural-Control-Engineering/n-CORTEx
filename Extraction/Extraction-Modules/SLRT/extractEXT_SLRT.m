function out = extractEXT_SLRT(filename)
    % Loads SLRT data saved in 'filename' and segments trials based on 
    % cont_trialCounter with data stored in a table. Currently, there is a 180 
    % second delay before the "behavior" starts. This is left out of the out for
    % now but can be included as an initial long trial. 

    % DONE - add session label
    % DONE - add column with column name - logged data type (e.g. event) pairings
    % DONE - allow seg_trialNum or cont_trialNum for segmentation data

    % load slrt data, get logged  signals
    slrt = load(filename);
    try
        logsout = slrt.realtimeLog.data;
    catch
        logsout = slrt.logsout;
    end
    signals = logsout.getElementNames();
    try
        trialNum = logsout.getElement("seg_trialNum").Values.Data;
    catch
        try
            trialNum = logsout.getElement("cont_trialNum").Values.Data;
        catch
            try
                trialNum = logsout.getElement("seg_trialCounter").Values.Data;
            catch
                error("Simulink model does not contain logged signal named 'cont_trialCounter' or 'seg_trialCounter")
            end
        end
    end

    % get session label
    file_parts = strsplit(filename, '/');
    file_name = strsplit(file_parts{end}, '.');
    session_label = file_name{1};

    % get signal types 
    signal_types = cell(length(signals), 2);
    for s = 1:length(signals)
        signal_split = strsplit(signals{s}, '_');
        if length(signal_split) == 2
            data_name = signal_split{2};
        else
            data_name = strcat(signal_split{2}, '_', signal_split{3});
        end
        signal_types{s,1} = data_name;
        signal_types{s,2} = signal_split{1};
    end
    
    % find start of each trial 
    trial_starts = find(trialNum == 1);
    trial_ends = zeros(length(trial_starts),1);
    for i = 1:length(trial_starts)
        % get end of each trial
        if i == length(trial_starts) 
            trial_ends(i) = length(trialNum);
        else
            trial_ends(i) = trial_starts(i+1)-1;
        end
        % populate table for current trial 
        row = table(i, {session_label}, 'VariableNames', {'trial_number', 'session_label'});
        % loop through logged signals 
        for s = 1:length(signals)
            signal_split = strsplit(signals{s}, '_');
            data = logsout.getElement(signals{s}).Values.Data;
            % segment data 
            data = data(trial_starts(i):trial_ends(i));
            % determine if event, continuous (cont), or tag 
            if length(signal_split) == 2
                data_name = signal_split{2};
            else
                data_name = strcat(signal_split{2}, '_', signal_split{3});
            end
            if strcmp(signal_split{1}, 'cont') || strcmp(signal_split{1}, 'signal')
                % cell array for continuous data
                row = [row, table({data}, 'VariableNames', {data_name})];
            elseif strcmp(signal_split{1}, 'tag')
                % single value for tag 
                row = [row, table(data(1), 'VariableNames', {data_name})];
            elseif strcmp(signal_split{1}, 'event')
                % index for for events 
                ind = find(data == 1);
                if ~isempty(ind)
                    try
                        row = [row, table(ind, 'VariableNames', {data_name})];
                    catch
                        row = [row, table(ind(1), 'VariableNames', {data_name})];
                    end
                else
                    row = [row, table(nan, 'VariableNames', {data_name})];
                end
            elseif ~strcmp(signal_split{1}, 'seg')
                % otherwise it's an invalid signal name 
                error(sprintf('Error: Invalid logged signal name: %s\nMust begin with cont_ (for continuous data), event_ (for e.g. triggers), or tags (single value for whole trial)\n', signals{s}))
            end
        end
        % add signal types 
        row = [row, table({signal_types}, 'VariableNames', {'signal_types'})];
        % put output table together 
        if i == 1
            out = row;
        else
            out = [out; row];
        end
    end
    out = alignSignalsToEvents(out)
end

function out = alignSignalsToEvents(slrt_data)
    signal_types = slrt_data(1,:).signal_types{1};
    signal_inds = find(strcmp(signal_types(:,2), 'signal'));
    event_inds = find(strcmp(signal_types(:,2), 'event'));
    out = slrt_data;
    for s = 1:length(signal_inds)
        sind = signal_inds(s);
        signal_name = signal_types{sind,1};
        for e = 1:length(event_inds)
            event_name = signal_types{event_inds(e),1};
            aligned_signals = cell(size(slrt_data,1), 1);
            for t = 1:size(slrt_data,1)
                event_ind = slrt_data(t,:).(event_name);
                if ~isnan(event_ind)
                    event_time = slrt_data(t,:).clock_time{1}(event_ind);
                    if t < size(slrt_data,1)
                        peri_time = [slrt_data(t,:).clock_time{1}; slrt_data(t+1,:).clock_time{1}] - event_time;
                        peri_signal = [slrt_data(t,:).(signal_name){1}; slrt_data(t+1,:).(signal_name){1}];
                    else
                        peri_time = slrt_data(t,:).clock_time{1} - event_time;
                        peri_signal = slrt_data(t,:).(signal_name){1};
                    end
                    aligned_signal = peri_signal(peri_time >= -3.5 & peri_time <= 5.0);
                    aligned_signals{t} = aligned_signal;
                end
            end
            col_title = strcat(event_name, '_aligned_', signal_name);
            out = [out, table(aligned_signals, 'VariableNames', {col_title})];
        end
    end
end