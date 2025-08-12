function df_filt = antiAlias(df_in, d, args)
    
    % CFG HEADER    
    Fs = args.Fs; % default = 2500
    contextWin = args.contextWin; % default = 50

    % chunkSize = args.chunkSize; % default = 1e6 samples
    % overlap = args.overlap; % default = 1e3 samples
  
    numSamps = size(df_in,2);
    numChans = size(df_in,1);    
    % apply anti-aliasing filter over data chunks (using sufficient
    % overlap)
    % transientLen = 3 * Fs;  % Safe-overlapping: 3 seconds of padding for low frequencies like 0.1 Hz
    transientLen = contextWin * Fs;  % Safe-overlapping: 30 seconds of padding for low frequencies like 0.1 Hz   
    windowLen = floor(transientLen / 5); % relative to expected safe chunking len, e.g. 3 seconds
    F = cell(numChans,1); % filtered results - temp storage var
    parfor i = 1:numChans
        df_chan = df_in(i,:);  
        % mirror padding
        
        % if transientLen < numSamps
        numChunks = ceil(numSamps/windowLen);
        for j = 1:numChunks % iterate over expected number of chunks
            samplePtr = (j-1)*windowLen+1;
            sampleMargin = length(df_chan) - samplePtr;
            lookBackLen = min([samplePtr-1, transientLen]);
            lookAheadLen = min([sampleMargin, transientLen]);
            % sample segmentation (chunk-wise filtering)
            df_chunk = df_chan(samplePtr-lookBackLen:samplePtr+lookAheadLen);                
            filteredChunk = filtfilt(d, df_chunk);
            % valid filtered signal extraction                
            validExtractionLen = min([sampleMargin,windowLen]);   
            extrctPtr = min([samplePtr, transientLen]);
            df_filt = filteredChunk(extrctPtr:extrctPtr+validExtractionLen);
            if j == 1
                F{i} = [F{i}, df_filt];
            else
                F{i} = [F{i}, df_filt(2:end)];
            end
        end      
    end
    df_filt = cat(1,F{:});

end