function [signalCol_aligned, timeCol_aligned] = nexAlign_signals(signalCol, timeCol_signal, timeCol_slrt, fs_slrt, t_preBuff, dim)
    
    eventIdxs = cellfun(@(t) find(t==0),timeCol_slrt,"UniformOutput",false);
    eventIdxs(cellfun(@isempty, eventIdxs)) = {NaN};
    % eventIdxs_mat = cell2mat(eventIdxs);
    % [latestEventIdx, rowIdx] = max(eventIdxs_mat);        
    % t_latestEvent = latestEventIdx / fs_slrt - t_preBuff;  % time of event, relative to signal  
    % t_event = latestEventIdx / fs_slrt - t_preBuff;
    t_events = cellfun(@(eventIdx) eventIdx/fs_slrt - t_preBuff, eventIdxs, "UniformOutput", false);
    % align all by latest instance of given 'event'
    if ~iscell(signalCol)
        signalCol = {signalCol};
    end
    if ~iscell(timeCol_signal)
        timeCol_signal = {timeCol_signal};
    end
    [signalCol_aligned, timeCol_aligned] = cellfun(@(x, t, t_event) nex_shiftSignal2Event(x, t, t_event, dim), signalCol, timeCol_signal, t_events, "UniformOutput",false);    
    
end