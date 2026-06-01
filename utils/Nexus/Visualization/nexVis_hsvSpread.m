function colors = nexVis_hsvSpread(n)
% Generate N maximally-distinct hues as an [N×3] RGB matrix.
    hues   = linspace(0, 1, n + 1);  hues(end) = [];
    colors = arrayfun(@(h) hsv2rgb([h, 0.8, 0.9]), hues, 'UniformOutput', false);
    colors = vertcat(colors{:});
end
