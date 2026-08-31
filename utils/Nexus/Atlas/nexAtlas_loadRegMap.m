function regMap = nexAtlas_loadRegMap(subjectDir)
% Load NTE channel-region table from a subject directory.
% Returns the regMap table (columns: shank, channel, X, Y, region, color).
%   Y  = µm from probe tip (0 = tip / deepest, increases toward brain surface).
%   channel = Neuropixels channel index (1–384).

    mapFile = fullfile(subjectDir, 'npxls', 'trajectory', 'imec0', 'map_channel-region.mat');
    s = load(mapFile);
    regMap = s.regMap;
end
