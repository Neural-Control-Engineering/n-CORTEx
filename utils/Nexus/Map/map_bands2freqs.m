function Map = map_bands2freqs(bands)
        bandFields = convertCharsToStrings(fieldnames(bands));
        LUT_bands = buildLUT_map(bandFields);
        bandEdges = table(structfun(@(band) band(2), bands),'VariableNames',{'axID'});
        Map = [bandEdges, LUT_bands];
end