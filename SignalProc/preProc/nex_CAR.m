function df_out = nex_CAR(df_in, args)
    % GLOBALCAR - Applies global common average referencing.
    % df_in: Input data (channels x time)
    % df_out: Output data after Global CAR
    %
    
    % CFG HEADER
    isLocal = args.isLocal; % default = 0 
    
    % Compute the global common average
    CAR_signal = mean(df_in, 1); % Average across all channels
    
    % Subtract the common average from each channel
    df_out = df_in - CAR_signal;
end
