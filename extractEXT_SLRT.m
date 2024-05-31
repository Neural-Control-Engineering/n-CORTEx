function out = extractEXT_SLRT(filename)
    % Loads SLRT data saved in 'filename' and segments trials based on 
    % cont_trialCounter with data stored in a table. Currently, there is a 180 
    % second delay before the "behavior" starts. This is left out of the out for
    % now but can be included as an initial long trial. 

    % TODO - add session label
    % TODO - add column with column name - logged data type (e.g. event) pairings
    
    slrt = load(filename);
    logsout = slrt.realtimeLog.data;
    signals = logsout.getElementNames();
    try
        trialNum = logsout.getElement("cont_trialNum").Values.Data;
    catch
        error("Simulink model does not contain logged signal named 'cont_trialCounter'")
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
        row = table(i, 'VariableNames', {'trial_number'});
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
                    row = [row, table(ind, 'VariableNames', {data_name})];
                else
                    row = [row, table(nan, 'VariableNames', {data_name})];
                end
            elseif ~strcmp(signal_split{1}, 'seg')
                % otherwise it's an invalid signal name 
                error(sprintf('Error: Invalid logged signal name: %s\nMust begin with cont_ (for continuous data), event_ (for e.g. triggers), or tags (single value for whole trial)\n', signals{s}))
            end
        end
        % put output table together 
        if i == 1
            out = row;
        else
            out = [out; row];
        end
    end
end