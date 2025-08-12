function df_out = nex_icaNoiseRm(df_in, args)
    % NEX_ICANOISERM - Removes independent components corresponding to noise using EEGLAB's ICA.
    % df_in: Input data (channels x time)
    % args.artifact_indices: Indices of components to remove (default = 1)
    % df_out: Output data after ICA-based noise removal
    
    % CFG HEADER
    
    % artifact_indices = args.artifact_indices; % default = 1

    artifact_indices = [1,2,3];

    [num_ch, num_samples] = size(df_in);
    
    % Run EEGLAB Infomax ICA
    eeglab('nogui'); % Ensure EEGLAB is initialized
    [weights, sphere] = runica(df_in, 'pca', num_ch);  % Apply PCA for stability
    
    % Compute ICA components
    icasig = weights * sphere * df_in;  % Independent components

    % Plot ICA components
    % figure;
    % num_components = min(25, num_ch); % Limit to 25 for visualization
    % for i = 1:num_components
    %     subplot(5, 5, i); % Arrange in a 5x5 grid
    %     plot(icasig(i, :));
    %     title(['IC ', num2str(i)]);
    % end
    % sgtitle('Independent Components Before Artifact Removal');

    % Zero out artifact components
    % icasig(artifact_indices, :) = 0;

    % Reconstruct signal
    % df_out = pinv(weights * sphere) * icasig;  
    df_out = icasig;
end
