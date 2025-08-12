function [bpDf, b] = poolBands(bands, f, dataFrame)
    bandNames = fieldnames(bands);
    b = [];
    bpDf = [];
    for i = 1:length(bandNames)
        band =string(bandNames{i});        
        bRange = bands.(band);
        bCond = (f>bRange(1) & f<bRange(2));
        bpDf = cat(2, bpDf, mean(dataFrame(:,bCond==1,:),2)); % store band-wise averages
        b = [b; band]; % store band 'axis' by name
    end
end