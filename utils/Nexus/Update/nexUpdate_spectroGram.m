function nexUpdate_spectroGram(nexon, spectroGram)  
    % when called, update dataframe and axes based on router cfg    
    spectroGram.dfID = spectroGram.Parent.dfID; % refresh dfID to parent dfID

    % STATE DEPENDENT BEHAVIOR
    switch spectroGram.isOnline
        case 0 % if offline grab from stored column (by opFcn augmented dfID)
            % retrieve dfID associated dataframe and axes
            dfID = spectrogram.dfID;
            f = grabDataFrame(nexon,sprintf("f_%s",dfID),[]); % use grabSpectrogram instead
            t = grabDataFrame(nexon,sprintf("t_%s",dfID),[]);
            df = grabDataFrame(nexon,dfID,[]);
        case 1 % if online, grab from parent
            % frameBufferID = sprintf("frameBuffer_chg_%s",spectroGram.dfID); % retrieve datafrom of parent channelgram  (this is a matrix of spectrograms for each channel)          
            % frameBuffer = grabDataFrame(nexon, frameBufferID,[]);
            % df = frameBuffer.frames;
            % ax = frameBuffer.ax;
            % t = ax.t;
            % f = ax.f;
            spectroGram.DF = spectroGram.Parent.DF_postOp;
    end

    % CALL OPERATION (state dependent)
    if ~isempty(spectroGram.opCfg.opFcn)
        spectroGram.DF_postOp = spectroGram.opCfg.opFcn(df_in, spectroGram.opCfg.entryParams); % consider here using magnitude or phase response transformations
    else
        spectroGram.DF_postOp = spectroGram.DF;
    end

    % spectroGram.dataFrame = df_op;
    % spectroGram.t = t;
    % spectroGram.f = f;

    % CALL VISUALIZATION
    visArgs = spectroGram.visCfg.entryParams;
    try
        spectroGram.visCfg.visFcn(spectroGram, visArgs);
    catch e
        disp(getReport(e));
    end
    
end