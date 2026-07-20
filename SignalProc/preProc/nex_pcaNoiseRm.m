function DF_out = nex_pcaNoiseRm(DF_in, args)
    % PCANOISERM - Removes first n_components PCA components from data.
    % df_in: Input data (channels x time)
    % n_components: Number of principal components to remove
    % df_out: Output data after PCA-based noise removal
   
    % CFG HEADER
    n_components = args.n_components; % default = 2
    
    df_in = DF_in.df;
    df_in = df_in(1:384,:); % remove 385'th column (peripheral metric)
    % Perform PCA
    [coeff, score, latent] = pca(df_in', 'Centered', true);  % latent = eigenvalues (variance explained)
    % [coeff, score, latent] = pca(df_out', 'Centered', true);  % latent = eigenvalues (variance explained)
    varExplained = latent / sum(latent)*100;
    fprintf("First: %d ",(varExplained(1)));
    fprintf("Second: %d \n",(varExplained(2)));
    varDiff = abs(diff(varExplained));
    n_components = sum(varDiff>50); % remove any vars explaining more than 90 %
    fprintf("Removing: %d Component(s) \n", n_components);
    
    % Reconstruct noise and subtract
    noise = score(:, 1:n_components) * coeff(:, 1:n_components)'; 
    df_out = df_in - noise'; 
    df_out_trim = df_out(:,5:end); % remove sharp edge

    % Mirror the input DF schema. Real-time capture feeds a FLAT DF (DF.t) built
    % by npxlsCapture_toLFP (flat is required so the DTS foliates as lfp_t/lfp_chans,
    % not ax_t/ax_chans); the offline path feeds a NESTED DF (DF.ax.t) read back
    % via dtsIO_composeDF. Read t from wherever it lives and emit the same shape.
    nested = isfield(DF_in, 'ax') && isfield(DF_in.ax, 't');
    if nested, t_full = DF_in.ax.t; else, t_full = DF_in.t; end
    t_trim = t_full(5:end); % align ax
    chans  = 1:size(df_in,1);

    DF_out.df = df_out_trim;
    if nested
        DF_out.ax.t = t_trim;
        DF_out.ax.chans = chans;
    else
        DF_out.t = t_trim;
        DF_out.chans = chans;
    end

    % Plot explained variance (eigenvalues)
    % figure;
    % plot(1:length(latent), latent / sum(latent) * 100, 'o-', 'LineWidth', 1.5);
    % xlabel('Principal Component Index');
    % ylabel('Explained Variance (%)');
    % title('Principal Component Significance');
    % grid on;
end
