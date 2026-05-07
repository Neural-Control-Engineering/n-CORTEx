function [C, matched] = nexOp_resolveGroupColors(nexon, clrKey, vals)
% Resolve per-row RGB colors for a single CLR column.
%
%   nexon  : root Nexon handle (for registry/LUT access)
%   clrKey : column name (e.g. 'sessionLabel_subj', 'condition', 'dropout')
%   vals   : [N×1] string / cell / numeric — one label per row
%
% Returns:
%   C       : [N×3] RGB double in [0 1]
%   matched : true  — a structured mapping (LUT or atlas) was found
%             false — HSV spread used (one distinct hue per unique value)
%
% Resolution order:
%   1. Registry LUT.(clrKey)  — exact label match
%      └ A-×-B labels not found directly → HSV circular-mean hue blend
%   2. Atlas registry          — dropout / chans (nex_axisColorFromRegistry)
%   3. HSV spread              — fallback, always succeeds

vals    = string(vals(:));
N       = numel(vals);
C       = zeros(N, 3);
matched = false;

% ── 1. Registry LUT ──────────────────────────────────────────────────────
try
    lut       = nexon.console.BASE.registry.LUT.(char(clrKey));
    lutLabels = string(lut.label);
    resolved  = false(N, 1);
    for k = 1:height(lut)
        m = vals == lutLabels(k);
        if ~any(m), continue; end
        hex = char(lut.color(k));
        C(m, :) = repmat([hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255, ...
                         sum(m), 1);
        resolved = resolved | m(:);
    end
    % Cross-comparison blend: 'A-×-B' labels not found verbatim in LUT
    for ui = find(~resolved)'
        blended = blendCrossLabel(char(vals(ui)), lut);
        if ~isempty(blended)
            C(ui, :) = blended;
            resolved(ui) = true;
        end
    end
    if any(resolved)
        C(~resolved, :) = repmat([0.55 0.55 0.55], sum(~resolved), 1);
        matched = true;
        return;
    end
catch
end

% ── 2. Atlas registry (dropout, chans, ...) ──────────────────────────────
[C_atlas, atlasHit] = nex_axisColorFromRegistry(nexon, clrKey, vals);
if atlasHit
    C       = C_atlas;
    matched = true;
    return;
end

% ── 3. HSV spread — one maximally distinct hue per unique value ───────────
uniq_v = unique(vals, 'stable');
n_u    = numel(uniq_v);
hues   = linspace(0, 1, n_u + 1); hues(end) = [];
for k = 1:n_u
    m = vals == uniq_v(k);
    C(m, :) = repmat(hsv2rgb([hues(k), 0.80, 0.90]), sum(m), 1);
end
% matched stays false

end

% ─────────────────────────────────────────────────────────────────────────
function rgb = blendCrossLabel(label, lut)
% HSV circular-mean blend for 'A-×-B[-×-C...]' cross-comparison labels.
    parts = strsplit(label, '-×-');
    if numel(parts) < 2, rgb = []; return; end
    lutLabels = string(lut.label);
    colors = zeros(0, 3);
    for p = 1:numel(parts)
        idx = find(lutLabels == string(strtrim(parts{p})), 1);
        if isempty(idx), continue; end
        hex = char(lut.color(idx));
        colors(end+1, :) = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255; %#ok<AGROW>
    end
    if isempty(colors), rgb = []; return; end
    if size(colors, 1) == 1, rgb = colors; return; end
    if all(vecnorm(colors - colors(1,:), 2, 2) < 1e-6), rgb = colors(1,:); return; end
    hsv    = rgb2hsv(colors);
    angles = hsv(:,1) * 2 * pi;
    hue    = mod(atan2(mean(sin(angles)), mean(cos(angles))) / (2*pi), 1);
    rgb    = hsv2rgb([hue, mean(hsv(:,2)), mean(hsv(:,3))]);
end
