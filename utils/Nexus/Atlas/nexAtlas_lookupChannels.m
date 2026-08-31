function [regionMAP, region_prob] = nexAtlas_lookupChannels(nexon, subjectID, chanIndices)
% Return atlas MAP region and probability for a set of channel indices.
%
%   subjectID   string key as in registry.SUBJ
%   chanIndices (n,) numeric Neuropixels channel indices
%
% Returns:
%   regionMAP   (n,) string — "unknown" for channels not in atlas
%   region_prob (n,) double — 0 for channels not in atlas

    n           = numel(chanIndices);
    regionMAP   = repmat("unknown", n, 1);
    region_prob = zeros(n, 1);

    try
        ann  = nexon.console.BASE.registry.SUBJ.(char(subjectID)).atlasAnnotation;
        atlasCh = ann.channel_indices(:);
        [tf, loc] = ismember(double(chanIndices(:)), double(atlasCh));
        regionMAP(tf)   = ann.regionMAP(loc(tf));
        region_prob(tf) = ann.region_prob(loc(tf));
    catch
    end
end
