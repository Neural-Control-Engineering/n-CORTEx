function [x_sq, b] = splitBands(bands, x, f, dim)
    % collapse spectral power across N channels into canonical neural
    % frequency bands
    bandNames = fieldnames(bands);
    x_sq = [];
    b = [];
    for i = 1:length(bandNames)
        band = bandNames{i};
        bRange = bands.(band);
        bandData = x(:,f>bRange(1) & f<bRange(2),:);
        bandData = mean(bandData,dim);
        x_sq = cat(3,x_sq,squeeze(bandData));
        b = [b, string(band)];
    end
end