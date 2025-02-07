function df_out = nex_localCAR(df_in, args)
    % LOCALCAR - Applies local common average referencing.
    % df_in: Input data (channels x time)
    % group_size: Number of channels per local group
    % df_out: Output data after Local CAR
    
    % CFG HEADER
    group_size = args.group_size; % default = 20

    [num_ch, ~] = size(df_in);
    df_out = df_in; % Initialize output

    for i = 1:group_size:num_ch
        idx = i:min(i+group_size-1, num_ch); % Define local group
        local_avg = mean(df_in(idx, :), 1);  % Compute local mean
        df_out(idx, :) = df_in(idx, :) - local_avg;
    end
end