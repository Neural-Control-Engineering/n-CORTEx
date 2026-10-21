function [cmap, matched] = nex_axisColorFromRegistry(nexon, axisID, axisVals)
% Resolve per-value RGB colors from the nexon atlas registry for a named axis.
%
% For axes like 'dropout' / 'regionDropout', axis values ARE region names
% and are looked up directly in regMap.region.
% For 'chans', axis values are channel indices; the function builds an
% inverse map (channel → region) then looks up colors.
% For 'f', axis values are frequency (Hz); colored by named band
% (nexon.console.BASE.params.bands) with a continuous within-band hue
% rotation — see colorByFrequency below. Doesn't need a subject regMap at
% all (bands are a global param, not per-subject atlas data), so it's
% routed before the regMap fetch.
% Any other axisID is not registry-backed and returns matched=false immediately.
%
% Colors in the registry are stored as 6-char hex strings (RRGGBB, no '#').
% Values not found in the regMap receive neutral grey [0.55 0.55 0.55].
% "NULL" (regionDropout baseline) always receives white-grey [0.82 0.82 0.82].
%
% Subjects are read from nexon.console.BASE.controlPanel.averagingSelection.
% If multiple subjects are selected their regMaps are vertically concatenated;
% the first occurrence of each region/channel wins on any duplicate.
%
% Returns:
%   cmap    — [numel(axisVals) × 3] RGB matrix (double, 0–1)
%   matched — true when at least one axis value was resolved from the registry

nVals   = numel(axisVals);
matched = false;
cmap    = lines(nVals);   % fallback

% ── Route by axis keyword ─────────────────────────────────────────────────
% Normalise: strip leading 'region' prefix so 'regionDropout' → 'dropout'
axID = lower(char(axisID));
axID = regexprep(axID, '^region', '');

if axID == "f"
    [colors, anyHit] = colorByFrequency(nexon, axisVals);
    if ~isempty(colors) && anyHit
        cmap = colors; matched = true;
    end
    return;
end

if axID == "t"
    % Fixed, global LUT (before/during/after) -- same category as 'f'
    % above, not subject-regMap-backed, so checked/returned here too,
    % before the regMap fetch. Only fires when axisVals are actually
    % epoch LABELS (the "epoch" mapID scheme -- see
    % Map/map_epochs2time.m, WIP.md #16), never for a plain continuous
    % time axis -- same numeric-vs-label disambiguation the 'chans' case
    % below uses for its own two-shapes-one-axis-name ambiguity.
    numVals = str2double(axisVals);
    if isempty(numVals) || any(isnan(numVals))
        [colors, anyHit] = colorByEpochName(nexon, string(axisVals));
        if ~isempty(colors) && anyHit
            cmap = colors; matched = true;
        end
    end
    return;
end

% ── Access registry / selected-subjects' pooled regMap ─────────────────────
% Shared with nexOp_regionDepthOrder.m (bar-chart region ordering) — same
% "which subjects' atlas data applies right now" resolution either way.
regMap = nexOp_selectedSubjectsRegMap(nexon);
if isempty(regMap), return; end

switch axID
    case 'dropout'
        [colors, anyHit] = colorByRegionName(regMap, string(axisVals));
    case 'chans'
        % "chans" values are either raw numeric channel indices (a genuine
        % physical-channel DF, e.g. LFP — colorByChannel's inverse
        % channel->region lookup) OR already-relabeled region-name strings
        % (a needsHR/block-reduced result, where "chans" was duplicated
        % from a co-indexed reduce-mode sweep — see nexAnalysis_cvPermute's
        % resolveCoIndexedSiblingIfLabeled). The caller (nexOp_
        % resolveGroupColors) always stringifies axisVals before this call,
        % so the two cases can't be told apart by MATLAB type here — route
        % by whether the VALUES themselves parse as numbers instead: a
        % region-labeled "chans" silently misses every lookup in
        % colorByChannel (double("STN") is NaN, matches nothing) and falls
        % through to the same generic HSV fallback "unit" already uses.
        numVals = str2double(axisVals);
        if ~isempty(numVals) && all(~isnan(numVals))
            [colors, anyHit] = colorByChannel(regMap, numVals);
        else
            [colors, anyHit] = colorByRegionName(regMap, string(axisVals));
        end
    case 'map'
        % "ax--regionMAP" — values are MAP region acronyms from atlas posterior
        [colors, anyHit] = colorByRegionName(regMap, string(axisVals));
    otherwise
        return;   % axis not registry-backed — caller uses lines() fallback
end

% Only flag matched when at least one value was actually resolved from the
% registry — prevents all-grey returns (e.g. fold labels "1","2",...) from
% being treated as a successful registry hit.
if ~isempty(colors) && anyHit
    cmap    = colors;
    matched = true;
end
end


% ── axis values ARE epoch labels (before/during/after) → fixed LUT ───────
% Global/fixed, not subject-regMap-backed -- same category as
% colorByFrequency's band LUT, not colorByRegionName's per-subject atlas
% lookup. Same hex values as map_epochs2time.m's own (unused-downstream)
% color column, kept in sync deliberately for visual consistency even
% though the two are otherwise independent pathways (see WIP.md #16 --
% confirmed no caller anywhere reads poolMap's own color output, so this
% function is the only color resolution that actually reaches a
% visualization).
function [colors, anyHit] = colorByEpochName(names)
    colors = [];
    anyHit = false;
    LUT = struct('before', [0.50 0.50 0.50], 'during', [0.24 0.94 0.46], ...
                 'after',  [0.50 0.50 0.50]);
    nVals  = numel(names);
    colors = repmat([0.55 0.55 0.55], nVals, 1);
    for i = 1:nVals
        key = lower(char(names(i)));
        if isfield(LUT, key)
            colors(i,:) = LUT.(key);
            anyHit = true;
        end
    end
end


% ── axis values ARE region names → look up regMap.region ─────────────────
function [colors, anyHit] = colorByRegionName(regMap, names)
    colors = [];
    anyHit = false;
    try
        mapRegions = string(regMap.region);
        nVals      = numel(names);
        colors     = repmat([0.55 0.55 0.55], nVals, 1);
        for i = 1:nVals
            nm = names(i);
            if nm == "NULL"
                colors(i,:) = [0 1 1];             % baseline — no dropout (cyan)
                anyHit = true;
                continue;
            end
            idx = find(mapRegions == nm, 1);       % first occurrence wins
            if ~isempty(idx)
                colors(i,:) = hexToRGB(regMap.color, idx);
                anyHit = true;
            end
        end
    catch
        colors = [];
    end
end


% ── axis values are channel indices → regMap.channel inverse lookup ───────
function [colors, anyHit] = colorByChannel(regMap, chanVals)
    colors = [];
    anyHit = false;
    try
        nVals  = numel(chanVals);
        colors = repmat([0.55 0.55 0.55], nVals, 1);
        nRows  = height(regMap);

        % Flatten regMap once: build parallel channel / row-index arrays and
        % a pre-decoded color matrix — avoids per-channel cellfun + hex decode.
        flatCh       = [];
        flatRow      = [];
        regionColors = zeros(nRows, 3);
        for r = 1:nRows
            regionColors(r,:) = hexToRGB(regMap.color, r);
            chs = double(regMap.channel{r});
            n   = numel(chs);
            flatCh  = [flatCh;  chs(:)];             %#ok<AGROW>
            flatRow = [flatRow; repmat(r, n, 1)];    %#ok<AGROW>
        end
        if isempty(flatCh), return; end

        % Single vectorized lookup — replaces 384 individual cellfun calls.
        [tf, loc] = ismember(double(chanVals(:)), flatCh);
        if ~any(tf), return; end
        colors(tf,:) = regionColors(flatRow(loc(tf)), :);
        anyHit = true;
    catch
        colors = [];
    end
end


% ── axis values are frequency (Hz) → named-band hue rotation ─────────────
% Not a flat one-color-per-band scheme like colorByRegionName — within a
% band, individual frequencies rotate continuously through hue space (a
% true mini-spectrum), band-to-band the hue keeps rotating too (each
% band owns a contiguous 1/nBands arc of the wheel, in band-definition
% order — delta,theta,alpha,beta,gamma today), so adjacent bands blend
% into each other overall, while saturation resets high at each band's
% own low edge and eases across the band — that reset is what still
% reads as a clear seam at each boundary even though hue itself never
% jumps. A frequency outside every band's range fades from its nearest
% band-edge color toward the base/accent color (nexon.settings.Colors.
% cyberGreen) over roughly one band-width, rather than looking undefined.
function [colors, anyHit] = colorByFrequency(nexon, freqVals)
    colors = [];
    anyHit = false;
    try
        bands = nexon.console.BASE.params.bands;
        bandNames = fieldnames(bands);
        nBands = numel(bandNames);
        if nBands == 0, return; end
        edges = cell2mat(struct2cell(bands));   % [nBands x 2], band-definition order
        lo = edges(:, 1); hi = edges(:, 2);

        BASE = [0.16 0.80 0.20];
        try
            BASE = nexon.settings.Colors.cyberGreen;
        catch
        end

        fv     = str2double(string(freqVals(:)));
        nVals  = numel(fv);
        colors = repmat(BASE, nVals, 1);

        for i = 1:nVals
            f = fv(i);
            if isnan(f), continue; end
            bi = find(f >= lo & f <= hi, 1);
            if ~isempty(bi)
                frac = (f - lo(bi)) / max(hi(bi) - lo(bi), eps);
                colors(i, :) = bandHueAt(bi, min(max(frac, 0), 1), nBands);
                anyHit = true;
                continue;
            end
            % Outside every band — fade from the nearest edge color to BASE
            if f < lo(1)
                edgeColor = bandHueAt(1, 0, nBands);
                span      = max(hi(1) - lo(1), eps);
                d         = lo(1) - f;
            else
                edgeColor = bandHueAt(nBands, 1, nBands);
                span      = max(hi(end) - lo(end), eps);
                d         = f - hi(end);
            end
            t = min(1, d / span);
            colors(i, :) = (1 - t) * edgeColor + t * BASE;
            anyHit = true;
        end
    catch
        colors = [];
    end
end

% Contiguous per-band hue arc: band bi (1-indexed) owns hue range
% [(bi-1)/nBands, bi/nBands); frac (0-1) is position within that band's
% own frequency range. Saturation resets to 1 at frac=0 and eases to
% ~0.65 by frac=1 — the visible "seam" at each new band's start.
function rgb = bandHueAt(bi, frac, nBands)
    hue = (bi - 1 + frac) / nBands;
    sat = 1.0 - 0.35 * frac;
    val = 0.90;
    rgb = hsv2rgb([hue, sat, val]);
end


% ── Extract one color from regMap.color column at row idx → [1×3] double ─
% Handles cell-of-hex, string array, or categorical columns.
function rgb = hexToRGB(colorCol, idx)
    try
        if iscell(colorCol)
            hex = char(colorCol{idx});
        else
            hex = char(colorCol(idx));
        end
        hex = strtrim(hex);
        if ~isempty(hex) && hex(1) == '#', hex = hex(2:end); end
        rgb = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255;
    catch
        rgb = [0.55 0.55 0.55];
    end
end
