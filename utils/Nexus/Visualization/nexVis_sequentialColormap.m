function cmap = nexVis_sequentialColormap(baseColor)
% nexVis_sequentialColormap  Black -> baseColor -> white, linear per-channel.
% Same formula plot_bandHierarchyGrid.m's own local sequentialColormap
% helper uses -- duplicated here (not refactored out of that proven,
% standalone-pipeline file) so nexObj_monoGram can use the identical
% gradient without touching it. Plain linear interpolation end-to-end, in
% contrast to the old cmap-cyberGreen.mat (a 256x3 table whose midpoint
% sits at a desaturated [0.35, 0.39, 0.35] grey-green rather than a clean
% progression) -- that's the "washed out" look this replaces.
%
%   baseColor : optional, default Nexus's own cyberGreen [0.24, 0.94, 0.46].
%
%   cmap : 256x3 RGB colormap.
    if nargin < 1 || isempty(baseColor), baseColor = [0.24, 0.94, 0.46]; end
    n = 128;
    seg1 = [linspace(0, baseColor(1), n)', linspace(0, baseColor(2), n)', linspace(0, baseColor(3), n)'];
    seg2 = [linspace(baseColor(1), 1, n)', linspace(baseColor(2), 1, n)', linspace(baseColor(3), 1, n)'];
    cmap = [seg1; seg2];
end
