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
    logsout = slrt.realtimeLog.data;
    signals = logsout.getElementNames();
    try
        trialNum = logsout.getElement("seg_trialNum").Values.Data;
    catch
        try
            trialNum = logsout.getElement("cont_trialNum").Values.Data;
        catch
            error("Simulink model does not contain logged signal named 'cont_trialCounter' or 'seg_trialCounter")
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
            if strcmp(signal_split{1}, 'cont')
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
end