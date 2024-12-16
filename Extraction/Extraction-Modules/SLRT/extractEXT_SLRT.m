function [out, slrt] = extractEXT_SLRT(filename)
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
        trial_starts = find(trialNum == 1);
    catch
        try
            trialNum = logsout.getElement("cont_trialNum").Values.Data;
            trial_starts = find(trialNum == 1);
        catch
            try
                trialNum = logsout.getElement("seg_trialCounter").Values.Data;
                trial_starts = find(trialNum == 1);
            catch
                try
                    trialNum = logsout.getElement("seg_trialGate").Values.Data;
                    trial_starts = find(diff(trialNum)>=1);                    
                catch
                    error("Simulink model does not contain logged signal named 'cont_trialCounter' or 'seg_trialCounter")
                end
            end
        end
    end

    % get session label
    file_parts = strsplit(filename, filesep());
    file_name = strsplit(file_parts{end}, '.');
    session_label = file_name{1};  
    
    % correct for missing clock time
    if all(~ismember(convertCharsToStrings(signals),"cont_clock_time"))        
        % Define signal data and properties
        % signalData = randn(1, 1000); % Example signal data
        signalData = [1:1:size(trialNum,1)]' ./ 1000;
        time = signalData; % Example time vector
        % Create a Simulink.SimulationData.Signal object
        sig = Simulink.SimulationData.Signal;
        sig.Name = 'cont_clock_time';
        sig.Values = timeseries(signalData, time);
        logsout = logsout.addElement(sig);
        % update 'signals' list
        signals = logsout.getElementNames();
    end

    % get signal types 
    signal_types = cell(length(signals), 2);
    m=1;
    % signal_types = {};
    for s = 1:length(signals)
        signal_split = strsplit(signals{s}, '_');
        if size(signal_split,2) > 1
            if length(signal_split) == 2
                data_name = signal_split{2};
            else
                data_name = strcat(signal_split{2}, '_', signal_split{3});
            end
            signal_types{m,1} = data_name;
            signal_types{m,2} = signal_split{1};
            m=m+1;
        end
    end
    % remove non-standardized signals
    nonemptySignals = cellfun(@(x) ~isempty(x), signal_types, "UniformOutput", true);       
    signal_types = signal_types(nonemptySignals(:,1),:);
    % signals = signals(nonemptySignals(:,1));
    signals = join(flip(signal_types,2),"_");    
    
    % find start of each trial 
    % trial_starts = find(trialNum == 1);
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
            % disp(signals{s});
            % Check for signal duplicates (user may have logged multiple
            % signals under the same name
            sig = logsout.getElement(signals{s});
            switch class(sig)
                case "Simulink.SimulationData.Signal"
                    data_raw = logsout.getElement(signals{s}).Values.Data;
                case "Simulink.SimulationData.Dataset"
                    % if exists duplicate, report the first of the
                    % duplicates
                    data_raw = sig.getElement(1).Values.Data;
            end            
            % segment data 
            if strcmp(signal_split{1}, 'cont') || strcmp(signal_split{1}, 'signal') || strcmp(signal_split{1}, 'event')
                % pre-buffer for first trial in session (special case)
                if i == 1
                    try
                        data = data_raw(trial_starts(i) - 3500: trial_ends(i)); % 3.5 add seconds prior (if possible)
                    catch e
                        disp(e);
                        try
                            data = data_raw(trial_starts(i)-500:trial_ends(i));
                        catch e
                            disp(e);
                            data = data_raw(trial_starts(i):trial_ends(i));
                        end
                    end
                else
                    data = data_raw(trial_starts(i):trial_ends(i));
                end
            else
                data = data_raw(trial_starts(i):trial_ends(i));
            end
            % determine if event, continuous (cont), or tag 
            if length(signal_split) == 2
                data_name = signal_split{2};
            elseif length(signal_split) > 2
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
                % error(sprintf('Error: Invalid logged signal name: %s\nMust begin with cont_ (for continuous data), event_ (for e.g. triggers), or tags (single value for whole trial)\n', signals{s}))
                warning(sprintf('Error: Invalid logged signal name: %s\nMust begin with cont_ (for continuous data), event_ (for e.g. triggers), or tags (single value for whole trial)\n', signals{s}))
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
    out = alignSignalsToEvents(out);
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
            aligned_times = cell(size(slrt_data,1), 1);
            for t = 1:size(slrt_data,1)
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
end