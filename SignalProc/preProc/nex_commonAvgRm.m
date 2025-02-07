function df_out = nex_commonAvgRm(df_in)
    % COMMONAVGRM - Removes common average signal from all channels.
    % df_in: Input data (channels x time)
    % df_out: Output data after CAR
    
    common_avg = mean(df_in, 1); % Compute the mean across channels
    df_out = df_in - common_avg; % Subtract from each channel
end