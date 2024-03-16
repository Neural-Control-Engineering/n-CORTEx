function [multiSpec, f, t] = multiSpectrogram(dataStream, fs, windowSize, overlap, dim)
    % compute time-frequency spectrogram for all channels along dim

    dataStreamLen = size(dataStream,2);
    if dataStreamLen > 10000; dataStream = dataStream(:,1:10000); end

    multiSpec = [];
    for i = 1:size(dataStream, dim)
        switch dim
            case 1
                dataChan = dataStream(i,:);
            case 2
                dataChan = dataStream(:,i);
        end
        
        % [spec, f, t] = spectrogram(dataChan, hanning(windowSize), overlap, [], fs);
        [spec, f, t] = spectrogram(dataChan, (windowSize), overlap, [], fs);        
        multiSpec = cat(3, multiSpec, spec);
    end
end