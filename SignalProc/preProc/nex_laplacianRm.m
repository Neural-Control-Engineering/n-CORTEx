function df_out = nex_laplacianRm(df_in, args)
    % LAPLACIANRM - Applies Laplacian spatial filtering to enhance local activity.
    % df_in: Input data (channels x time)
    % df_out: Output data after Laplacian referencing

    % CFG HEADER    
    
    [num_ch, ~] = size(df_in);
    df_out = df_in; % Initialize output
    
    for ch = 2:num_ch-1
        df_out(ch, :) = df_in(ch, :) - 0.5 * (df_in(ch-1, :) + df_in(ch+1, :));
    end
end