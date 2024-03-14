function [t_1, t_2] = alignTimes(t1, t2)
    % align t2 time ax to t1 time ax
    % t = time axis
    % Fs = sampling freq (Hz)
    % preBuff = sample buffer / i.e. number of samples before event of interest
    t_1 = t1.t - t1.preBuff / t1.Fs;
    t_2 = t2.t - t2.preBuff / t2.Fs;
end