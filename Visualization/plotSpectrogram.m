function plotSpectrogram(params, signalIn, fs, windowSize, overlap)
    % Input:
    %   params: Structure containing parameters for the spectrogram
    %   signalIn: 385xN dimensional input signal

    % Extract parameters from the structure
    % fs = params.fs;                 % Sampling frequency
    % windowSize = params.windowSize; % Window size for spectrogram
    % overlap = params.overlap;       % Overlap between windows

    % Compute the spectrogram
    [S, F, T] = spectrogram(signalIn, windowSize, overlap, [], fs);

    % Plot the spectrogram
    figure;
    imagesc(T, F, 10*log10(abs(S)));
    axis xy; % Display the y-axis in the correct orientation
    colormap('jet');
    colorbar;
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title('Spectrogram');
end