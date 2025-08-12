function [x_shift, t_shift] = nex_shiftSignal2Event(x, t, t_event, dim)
    % Create a full index array for all dimensions
    % subs = repmat({':'}, 1, ndims(df));  
    % subs{dim} = idxs;  % Replace the target dimension with the specified indexes 
    if isempty(x)
        x_shift = [];
        t_shift = [];
    elseif isnan(x)
        x_shift = nan;
        t_shift = nan;
    else
        [tDiff, idx_event] = (min(abs(t-t_event))); % relative to signal time
        [onsetDiff, idx_onset] = min(abs(t));
        % idxShift = idx_event - idx_onset;
        idxShift = idx_onset - idx_event;
        x_shift = circshift(x,idxShift,dim);
        t_shift = t - t(idx_event);
    end
end