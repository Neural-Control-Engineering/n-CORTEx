function cdataRGB = nex_hueGradientCData(Z, anchorRGB, cLim, dim)
% nex_hueGradientCData  Single-hue sequential colormap for a 2-D heatmap,
% anchored per row, per column, or per cell — so each part of the surface
% rides its OWN hue instead of one shared colormap for the whole thing.
%
% Dark-to-anchor gradient: the LOW end is a dark/deep shade of the anchor
% hue (brightness pushed low, same hue/saturation), the HIGH end is the
% anchor color itself at full, vivid strength — low value reads as
% dark/muted, high value reads as the region's own true, vivid color.
%
%   Z         : [M×N] data matrix (the heatmap's own values)
%   anchorRGB : one of —
%                 [M×3]   one anchor per ROW (dim=1, default) — e.g. one
%                         atlas region color per row, from
%                         nex_axisColorFromRegistry
%                 [N×3]   one anchor per COLUMN (dim=2)
%                 [M×N×3] one anchor per CELL — e.g. a row-anchor ×
%                         column-anchor blend already computed by the
%                         caller (two simultaneous CLR axis selections);
%                         dim is ignored in this case
%   cLim      : [low high] — Z is normalized against this range (same
%               role clim(ax,[cLim_low cLim_high]) plays for the plain
%               scalar-CData path), clamped to [0,1] after normalizing.
%   dim       : 1 = one anchor per ROW (default), 2 = one anchor per COLUMN.
%               Ignored when anchorRGB is already [M×N×3].
%
%   cdataRGB  : [M×N×3] truecolor CData — assign directly to a
%               surf/patch/image object's CData; MATLAB auto-detects
%               truecolor mode from the 3rd-dim size.
    if nargin < 4 || isempty(dim), dim = 1; end

    [M, N] = size(Z);
    lo = cLim(1); hi = cLim(2);
    if hi <= lo, hi = lo + eps; end
    normZ = (Z - lo) / (hi - lo);
    normZ = min(max(normZ, 0), 1);
    normZ(isnan(normZ)) = 0;

    % ── Per-cell anchor grid — direct linear RGB blend (dark -> anchor
    % with only 2 control points IS linear; no need for buildColorMap's
    % 256-stop pchip machinery per cell, which would be needlessly
    % expensive at M*N calls).
    if ndims(anchorRGB) == 3
        if ~isequal([size(anchorRGB, 1), size(anchorRGB, 2)], [M, N])
            error('nex_hueGradientCData:sizeMismatch', ...
                'Per-cell anchorRGB is %s but Z is %s.', mat2str(size(anchorRGB)), mat2str(size(Z)));
        end
        darkGrid = zeros(M, N, 3);
        for i = 1:M
            for j = 1:N
                darkGrid(i, j, :) = shadeTowardDark(squeeze(anchorRGB(i, j, :))');
            end
        end
        cdataRGB = darkGrid + normZ .* (anchorRGB - darkGrid);
        return;
    end

    % ── Per-row / per-column anchor — buildColorMap.m per row/col (M or N
    % calls, not M*N) so a non-integer 0-255 index still lands correctly
    % on the same gradient every other cell in that row/col shares.
    if dim == 2
        normZt = normZ';
        [Mp, Np] = deal(N, M);
    else
        normZt = normZ;
        [Mp, Np] = deal(M, N);
    end
    if size(anchorRGB, 1) ~= Mp
        error('nex_hueGradientCData:sizeMismatch', ...
            'anchorRGB has %d row(s) but Z has %d along dim %d.', size(anchorRGB, 1), Mp, dim);
    end
    cdataRGB = zeros(Mp, Np, 3);
    for i = 1:Mp
        darkAnchor = shadeTowardDark(anchorRGB(i, :));
        CT  = buildColorMap([darkAnchor; anchorRGB(i, :)]);   % 256×3, dark -> anchor
        idx = min(255, max(0, round(normZt(i, :) * 255))) + 1;
        cdataRGB(i, :, :) = reshape(CT(idx, :), 1, Np, 3);
    end
    if dim == 2
        cdataRGB = permute(cdataRGB, [2 1 3]);
    end
end

% ── Dark/deep shade of anchor's own hue ──────────────────────────────────
% Same hue AND saturation as the anchor, brightness/value pushed low — a
% deep shade toward black, not a desaturated tint toward white/gray.
% Tunable (the 0.12 floor) if the gradient reads too dark or not dark
% enough at the low end.
function rgb = shadeTowardDark(anchor)
    hsv    = rgb2hsv(anchor);
    hsv(3) = 0.12;
    rgb    = hsv2rgb(hsv);
end
