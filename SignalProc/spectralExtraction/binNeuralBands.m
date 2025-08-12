function [PSD_bands, b] = binNeuralBands(bands, PSD, f_psd)
    bandNames = fieldnames(bands);
    b = [];
    PSD_bands = [];
    for i = 1:length(bandNames)
        band = bandNames{i};
        bRange = bands.(band);
        bCond = (f_psd > bRange(1)) & (f_psd < bRange(2));
        bandSlice = PSD(:,bCond==1,:);
        bandSlice = squeeze(mean(bandSlice,2));
        PSD_bands = cat(3, PSD_bands, bandSlice);
        b = [b; string(band)];
    end
end