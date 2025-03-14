function nexExport_spectroScope(nexObj, args)

    % CFG HEADER  

    labelVals = nexObj.UserData.labelVals;
    labelKeys = nexObj.UserData.labelKeys;
    labelIDs = convertCharsToStrings(fieldnames(labelKeys))';
    params = nexObj.nexon.console.BASE.params;

    df = nexObj.DF_postOp.df;
    f = nexObj.DF_postOp.ax.f;
    t = nexObj.DF_postOp.ax.t;
    ax = nexObj.DF_postOp.ax;
    chans = nexObj.DF_postOp.ax.chans;
    % interject alternate storage path
    ftrPath = params.paths.Data.FTR.local;
    ftrPath_mod = strrep(ftrPath,"/home/user","/media/user/Expansion"); % TEMPORARY
    %% SPECTRAL    
    % write/append csv    
    stackPath = fullfile(ftrPath_mod,"TRAIN",sprintf("%s_spectral",func2str(nexObj.opCfg.opFcn)));
    % save labelKey     
    [chanGrid, timeGrid] = ndgrid(1:size(df,1), 1:size(df,3));
    arrayfun(@(chan, time) featureStack(stackPath, formatSpecParamSample(df(chan,:,time),"spectral",ax,[]), [chans(chan), t(time), labelVals'],["channel","time",labelIDs], labelKeys), chanGrid, timeGrid); % spectral pathway
    [X, Y] = arrayfun(@(chan,time) featureStack(df(chan,:,time), [chans(chan), t(time), labelVals']), chanGrid, timeGrid, "UniformOutput",false); % spectral pathway    
    X = reshape(X,[size(X,1)*size(X,2),1]);
    Y = reshape(Y,[size(Y,1)*size(Y,2),1]);
    X = cat(1,X{:});
    Y = cat(1,Y{:});
    writeToFeatureStack(stackPath, X, Y, ["channel","time",labelIDs], labelKeys); % spectral pathway 
    % arrayfun(@(chan,time) appendToFeatureStack(stackPath, df(chan,:,time), [chan, time, labelVals'], ["channel","time",labelIDs]), chanGrid, timeGrid); % spectral pathway    
    %% SPATIAL    
    % write/append csv
    stackPath = fullfile(ftrPath_mod,"TRAIN",sprintf("%s_spatial",func2str(nexObj.opCfg.opFcn)));
    [freqGrid, timeGrid] = ndgrid(1:size(df,2), 1:size(df,3));
    arrayfun(@(freq, time) appendToFeatureStack(stackPath, formatSpecParamSample(df(:,:,time),"spectral",ax,freq), [f(freq), t(time), labelVals'],["channel","time",labelIDs], labelKeys), freqGrid, timeGrid); % spectral pathway    
    %% TEMPORAL
    stackPath = fullfile(ftrPath_mod,"TRAIN",sprintf("%s_temporal",func2str(nexObj.opCfg.opFcn)));
    [freqGrid, chanGrid] = ndgrid(1:size(df,2), 1:size(df,1));
    arrayfun(@(freq, chan) appendToFeatureStack(stackPath, formatSpecParamSample(squeeze(df(chan,:,:)),"spectral",ax,freq), [f(freq), chans(chan), labelVals'],["channel","time",labelIDs], labelKeys), freqGrid, chanGrid); % spectral pathway    
    % arrayfun(@(freq,chan) appendToFeatureStack(stackPath, df(chan,freq,:), [freq, chan, labelVals'], ["frequency","time",labelIDs]), freqGrid, chanGrid); % spectral pathway       
    %% BATCH
    % write batch sample
    X = nexObj.DF_postOp.df;
    batchPath = fullfile(ftrPath_mod,"TRAIN",sprintf("%s_batch",func2str(nexObj.opCfg.opFcn)));
    % retrieve sample index details
    foldNum = nexObj.UserData.foldNum;
    sampleNum = nexObj.UserData.sampleNum;
    writeBatchSample(batchPath, X, foldNum, sampleNum, labelIDs);
end