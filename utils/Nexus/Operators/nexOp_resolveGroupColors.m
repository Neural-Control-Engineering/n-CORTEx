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

% ── 1. Registry LUT ──────────────────────────────────────────────────────
% Extracted to nex_registryLUTColor.m -- shared verbatim with
% nex_axisColorFromRegistry.m's "t"/epoch case, which needs the identical
% lookup but can't call THIS function (its own step 2, below, calls back
% into nex_axisColorFromRegistry -- a direct call the other way would
% recurse infinitely the first time this lookup misses).
[C, matched] = nex_registryLUTColor(nexon, clrKey, vals);
if matched
    return;
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
