function [C, matched] = nex_registryLUTColor(nexon, clrKey, vals)
% nex_registryLUTColor  Exact-label color lookup against
% nexon.console.BASE.registry.LUT.(clrKey) -- the single "registry LUT"
% step both nexOp_resolveGroupColors.m (its own step 1) and
% nex_axisColorFromRegistry.m (its "t"/epoch case) need, factored out so
% neither duplicates it. Extracted verbatim from
% nexOp_resolveGroupColors.m's own former step-1 block -- same behavior,
% not a rewrite.
%
% MUST stay free of any call back into nexOp_resolveGroupColors.m or
% nex_axisColorFromRegistry.m -- both of those call INTO this function,
% so a call the other way would recurse (confirmed directly:
% nex_axisColorFromRegistry's "t" case calling nexOp_resolveGroupColors
% would recurse infinitely the first time this LUT lookup misses, since
% nexOp_resolveGroupColors's OWN step 2 calls nex_axisColorFromRegistry
% right back).
%
%   nexon  : root Nexon handle (for registry/LUT access)
%   clrKey : the registry.LUT key to look up (e.g. 'sessionLabel_subj',
%            'condition', 'dropout', 't')
%   vals   : [N×1] string / cell / numeric — one label per row/position
%
%   C       : [N×3] RGB double in [0 1] (undefined/grey where unmatched)
%   matched : true only if at least one value resolved from the registry
%             (mirrors nexOp_resolveGroupColors's own "don't claim a
%             match on an all-grey result" convention)

    vals    = string(vals(:));
    N       = numel(vals);
    C       = zeros(N, 3);
    matched = false;

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
        end
    catch
    end
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
