function DF_dropout = nexOp_dropoutAx(DF, axSlice)
    % replace indexed slice with noise of equivalent size
    noiseSlice = []; % gaussian noise scaled to dynamic range of other channels
    DF_dropout = DF;
    DF_dropout.df(axSlice{:}) = noiseSlice;
    
end