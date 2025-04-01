function [signalCol_aligned, timeCol_aligned] = nexAlign_signals(signalCol, timeCol_signal, timeCol_slrt, fs_slrt, t_preBuff, dim)
    
    eventIdxs = cellfun(@(t) find(t==0),timeCol_slrt,"UniformOutput",false);
    eventIdxs(cellfun(@isempty, eventIdxs)) = {NaN};
    eventIdxs_mat = cell2mat(eventIdxs);
    [latestEventIdx, rowIdx] = max(eventIdxs_mat);    
    t_latestEvent = latestEventIdx / fs_slrt - t_preBuff;  % time of event, relative to signal  
    % align all by latest instance of given 'event'
    [signalCol_aligned, timeCol_aligned] = cellfun(@(x, t) nex_shiftSignal2Event(x, t, t_latestEvent, dim), signalCol, timeCol_signal, "UniformOutput",false);    
    
end