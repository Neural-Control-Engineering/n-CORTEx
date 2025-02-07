function df_out = nex_icaNoiseRm(df_in, args)
    % ICANOISERM - Removes independent components corresponding to noise.
    % df_in: Input data (channels x time)
    % artifact_indices: Indices of components to remove
    % df_out: Output data after ICA-based noise removal
    
    % CFG HEADER
    artifact_indices = args.artifact_indices; % default = 1

    [num_ch, ~] = size(df_in);
    
    % Run FastICA
    [icasig, A, W] = fastica(df_in, 'numOfIC', num_ch);
    
    % Zero out artifact components
    icasig(artifact_indices, :) = 0;
    
    % Reconstruct signal
    df_out = A * icasig;    
end