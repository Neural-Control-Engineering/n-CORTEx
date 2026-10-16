function Map = map_bands2freqs(bands)
        bandFields = convertCharsToStrings(fieldnames(bands));
        LUT_bands = buildLUT_map(bandFields);
        % axID must be each band's LOWER edge (band(1)) — nexObj_poolMap.
        % getBinEdges' region-table algorithm (shared with the chans/region
        % case) treats axID as each region's STARTING boundary, building
        % bin edges as [first start; every other start; axMax+1]. Using the
        % upper edge (band(2)) here shifted every band's boundary down by
        % one slot (6 Hz labeled "delta" instead of "theta", etc.) and let
        % gamma silently absorb everything above its own true upper bound.
        bandEdges = table(structfun(@(band) band(1), bands),'VariableNames',{'axID'});
        Map = [bandEdges, LUT_bands];

        % Sentinel row at the highest band's own upper edge — otherwise
        % nexObj_poolMap.getBinEdges' shared region-table algorithm
        % extends the LAST bin all the way to the axis's true max (correct
        % for chans/regions, where every channel must belong to SOME
        % region; wrong here — a frequency above the top declared band has
        % no business being labeled with that band just because it's last).
        % Filtered out automatically (keep = mapAxID <= axMax) whenever the
        % axis never actually reaches this edge, so this is a no-op unless
        % the overflow it guards against is real.
        topEdge = max(structfun(@(band) band(2), bands));
        sentinelRow = table(topEdge, "none", "808080", ...
            'VariableNames', Map.Properties.VariableNames);
        Map = [Map; sentinelRow];
end