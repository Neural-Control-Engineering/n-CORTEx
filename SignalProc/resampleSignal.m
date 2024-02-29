function resampledSignal = resampleSignal(originalSignal, factor, method)
    % Input:
    %   - originalSignal: The original signal to be resampled.
    %   - factor: Resampling factor (e.g., 2 for upsampling, 0.5 for downsampling).
    %   - method: Resampling method ('linear', 'nearest', 'pchip', etc.).

    % Calculate the new length after resampling
    newLength = round(length(originalSignal) * factor);

    % Resample the signal
    resampledSignal = resample(originalSignal, newLength, length(originalSignal));
end