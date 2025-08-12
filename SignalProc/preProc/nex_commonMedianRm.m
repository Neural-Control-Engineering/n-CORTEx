function df_out = nex_commonMedianRm(df_in, args)
    % COMMONMEDIANRM - Removes common median signal from all channels.
    % df_in: Input data (channels x time)
    % df_out: Output data after CMR

    % CFG HEADER  
    
    common_median = median(df_in, 1); % Compute the median across channels
    df_out = df_in - common_median; % Subtract from each channel
end