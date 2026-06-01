function Map = map_regions2chans(regMap)
        regMap_flip = flip(regMap,1);
        regions = convertCharsToStrings(regMap_flip.region);
        regs_0 = regions;
        regs_1 = regions([2:end, 1]);
        idx_edges = find(~strcmp(regs_0, regs_1));
        % idx_edges = [find(~strcmp(regions(1:end-1), regions(2:end))); size(regions,1)];
        % edges = ([size(regions,2) - ([1, find(~strcmp(regions(1:end-1), regions(2:end))) + 1]-1),0])';
        % bandFields = convertCharsToStrings(fieldnames(bands));
        % LUT_bands = buildLUT(bandFields);
        Map = table(regMap_flip.channel(idx_edges), regMap_flip.region(idx_edges), regMap_flip.color(idx_edges), 'VariableNames',{'axID','mapID','color'});
        % bandEdges = table(structfun(@(band) band(2), bands),'VariableNames',{'f'});
        % Map = [bandEdges, LUT_bands];
end