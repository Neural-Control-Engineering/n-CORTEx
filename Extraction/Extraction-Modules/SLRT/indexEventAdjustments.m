function SLRT = indexEventAdjustments(SLRT, Fs)
    if isempty(Fs)
       Fs = 1000; % default
    end
    slrtCols = convertCharsToStrings(SLRT.Properties.VariableNames);
    signal_types = SLRT(1,:).signal_types{1};
    event_inds = find(strcmp(signal_types(:,2), 'event'));
    for e = 1:length(event_inds)
        event_name = signal_types{event_inds(e),1};
        % find event-coupled advances of delays (keywords)
        % eventAdvances = find(SLRT.Properties.VariableNames);
        inds_eventAdj = find(strcmp(slrtCols,sprintf("%s_advance",event_name))|strcmp(slrtCols,sprintf("%s_delay",event_name)));
        for i = 1:length(inds_eventAdj) % for now, should only be 1 or 0
            ind_eventAdj = inds_eventAdj(i);
            t_eventAdjustments = SLRT(:,ind_eventAdj);
            eventAdjName = t_eventAdjustments.Properties.VariableNames{1};            
            adjType = split(eventAdjName,"_"); adjType = (adjType{2}); adjType(1) = upper(adjType(1));
            newEventName = sprintf("%s%s",event_name,adjType);
            t_newEvents = table2cell(t_eventAdjustments);
            idxs_origEvent = (SLRT.(event_name));            
            switch adjType
                case 'Advance'
                    idxs_newEvent = cellfun(@(t, idx) round(idx - t * Fs), t_newEvents, idxs_origEvent, "UniformOutput", false);
                case 'Delay'
                    idxs_newEvent = cellfun(@(t, idx) round(idx + t * Fs), t_newEvents, idxs_origEvent, "UniformOutput", false);
            end
            % register new event in signals
            signal_types = [signal_types; {convertStringsToChars(newEventName), 'event'}];
            % SLRT = [SLRT, table()]
            SLRT.(newEventName) = idxs_newEvent;
        end                
    end
    % SLRT.signal_types = signal_types;
    newSignalTypes = cellfun(@(x) signal_types, SLRT.signal_types, "UniformOutput",false);
    SLRT.signal_types = newSignalTypes;
end