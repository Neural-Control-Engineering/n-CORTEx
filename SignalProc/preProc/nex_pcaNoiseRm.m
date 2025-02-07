function df_out = nex_pcaNoiseRm(df_in, args)
    % PCANOISERM - Removes first n_components PCA components from data.
    % df_in: Input data (channels x time)
    % n_components: Number of principal components to remove
    % df_out: Output data after PCA-based noise removal
   
    % CFG HEADER
    n_components = args.n_components; % default = 2
    
    % Perform PCA
    [coeff, score, latent] = pca(df_in', 'Centered', true);  % latent = eigenvalues (variance explained)
    
    % Reconstruct noise and subtract
    noise = score(:, 1:n_components) * coeff(:, 1:n_components)'; 
    df_out = df_in - noise'; 

    % Plot explained variance (eigenvalues)
    % figure;
    % plot(1:length(latent), latent / sum(latent) * 100, 'o-', 'LineWidth', 1.5);
    % xlabel('Principal Component Index');
    % ylabel('Explained Variance (%)');
    % title('Principal Component Significance');
    % grid on;
end
