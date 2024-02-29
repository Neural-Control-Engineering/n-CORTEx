function [x_sq, b] = squeezeBands(bands, x, f, dim)
    % collapse spectral power across N channels into canonical neural
    % frequency bands
    bandNames = fieldnames(bands);
    x_sq = [];
    b = [];
    for i = 1:length(bandNames)
        band = bandNames{i};
        bRange = bands.(band);
        bandData = x(f>bRange(1) & f<bRange(2),:,:);
        bandData = mean(bandData,dim);
        x_sq = cat(1,x_sq,bandData);
        b = [b, string(band)];
    end
end