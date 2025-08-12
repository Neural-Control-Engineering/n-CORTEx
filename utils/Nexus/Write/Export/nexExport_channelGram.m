function nexExport_channelGram(nexObj, args)
    % export all three leading dims + tensor

    % CFG HEADER    

    labelVals = nexObj.UserData.labelVals;
    labelKeys = nexObj.UserData.labelKeys;
    % labelIDs = convertCharsToStrings(fieldnames(labelKeys))';
    labelIDs = nexObj.UserData.labelIDs;
    params = nexObj.nexon.console.BASE.params;

    df = nexObj.DF_postOp.df;
    f = nexObj.DF_postOp.ax.f;
    t = nexObj.DF_postOp.ax.t;
    chans = nexObj.DF_postOp.ax.chans;
    % interject alternate storage path
    ftrPath = params.paths.Data.FTR.local;
    ftrPath_mod = strrep(ftrPath,"/home/user","/media/user/Expansion"); % TEMPORARY
    %% SPECTRAL    
    % write/append csv    

    % stackPath = fullfile(ftrPath_mod,"TRAIN",sprintf("%s_spectral",func2str(nexObj.opCfg.opFcn)));
    % [chanGrid, timeGrid] = ndgrid(1:size(df,1), 1:size(df,3));
    % [X, Y] = arrayfun(@(chan,time) featureStack(df(chan,:,time), [chans(chan), t(time), labelVals']), chanGrid, timeGrid, "UniformOutput",false); % spectral pathway    
    % X = reshape(X,[size(X,1)*size(X,2),1]);
    % Y = reshape(Y,[size(Y,1)*size(Y,2),1]);
    % X = cat(1,X{:});
    % Y = cat(1,Y{:});
    % writeToFeatureStack(stackPath, X, Y, ["channel","time",labelIDs], labelKeys); % spectral pathway    

    %% SPATIAL    
    % write/append csv

    % stackPath = fullfile(ftrPath_mod,"TRAIN",sprintf("%s_spatial",func2str(nexObj.opCfg.opFcn)));
    % [freqGrid, timeGrid] = ndgrid(1:size(df,2), 1:size(df,3));
    % [X, Y] =arrayfun(@(freq,time) featureStack(df(:,freq,time)', [f(freq), t(time), labelVals']), freqGrid, timeGrid, "UniformOutput",false); % spectral pathway      
    % X = reshape(X,[size(X,1)*size(X,2),1]);
    % Y = reshape(Y,[size(Y,1)*size(Y,2),1]);
    % X = cat(1,X{:});
    % Y = cat(1,Y{:});
    % writeToFeatureStack(stackPath, X, Y, ["frequency","time",labelIDs], labelKeys); % spectral pathway    

    %% TEMPORAL
    stackPath = fullfile(ftrPath_mod,"TRAIN",sprintf("%s_temporal",func2str(nexObj.opCfg.opFcn)));
    [freqGrid, chanGrid] = ndgrid(1:size(df,2), 1:size(df,1));
    [X,Y] = arrayfun(@(freq,chan) featureStack(squeeze(df(chan,freq,:))', [f(freq), chans(chan), labelVals']), freqGrid, chanGrid, "UniformOutput",false); % spectral pathway    
    X = reshape(X,[size(X,1)*size(X,2),1]);
    Y = reshape(Y,[size(Y,1)*size(Y,2),1]);
    X = cat(1,X{:});
    Y = cat(1,Y{:});
    writeToFeatureStack(stackPath, X, Y, ["channel","frequency",labelIDs], labelKeys); % spectral pathway    
    %% BATCH

    % % write batch sample
    % X = nexObj.DF_postOp.df;
    % batchPath = fullfile(ftrPath_mod,"TRAIN",sprintf("%s_batch",func2str(nexObj.opCfg.opFcn)));
    % % retrieve sample index details
    % foldNum = nexObj.UserData.foldNum;
    % sampleNum = nexObj.UserData.sampleNum;
    % writeBatchSample(batchPath, X, foldNum, sampleNum, labelIDs, labelVals);    
end