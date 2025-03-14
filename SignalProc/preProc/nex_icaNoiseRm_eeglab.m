function df_out = nex_icaNoiseRm_eeglab(df_in, args)
    % ICANOISERM_EEGLAB - Removes noise from EEG/ephys data using EEGLAB's ICA.
    % df_in: Input data (channels x time)
    % fs: Sampling frequency (Hz)
    % args.artifact_indices: Indices of components to remove (manual mode)
    % args.auto_flag: Use automatic ICA artifact rejection if set to true
    % df_out: Cleaned output data after ICA-based noise removal
    
    % Load EEGLAB
    eeglab;

    % CFG HEADER
    fs = args.fs; % default = 500
    artifact_indices = args.artifact_indices; % default = 1
    auto_flag = args.auto_flag; % default = 1

    % Create EEGLAB EEG structure
    EEG = pop_importdata('dataformat', 'array', 'data', df_in, 'srate', fs);

    % High-pass filter (recommended for ICA)
    EEG = pop_eegfiltnew(EEG, 1, []);

    % Run ICA using EEGLAB's method
    EEG = pop_runica(EEG, 'extended', 1, 'pca', min(size(df_in,1)-1, 64));  % Use PCA if needed

    % Check if auto flag is set for automatic artifact removal
    if isfield(args, 'auto_flag') && args.auto_flag
        % Use ICLabel to classify components
        EEG = pop_iclabel(EEG, 'default');

        % Automatically flag artifact components
        EEG = pop_icflag(EEG, [NaN NaN; 0.8 1; 0.8 1; 0.8 1; 0.8 1; 0.8 1; NaN NaN]);

        % Remove flagged ICA components
        EEG = pop_subcomp(EEG);
    elseif isfield(args, 'artifact_indices')
        % Manually remove specified components
        EEG = pop_subcomp(EEG, args.artifact_indices);
    else
        error('Specify artifact indices or enable auto_flag for ICLabel');
    end

    % Extract cleaned data
    df_out = EEG.data;
end
