function [cmap, matched] = nex_axisColorFromRegistry(nexon, axisID, axisVals)
% Resolve per-value RGB colors from the nexon atlas registry for a named axis.
%
% For axes like 'dropout' / 'regionDropout', axis values ARE region names
% and are looked up directly in regMap.region.
% For 'chans', axis values are channel indices; the function builds an
% inverse map (channel → region) then looks up colors.
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

% ── Access registry ───────────────────────────────────────────────────────
try
    reg = nexon.console.BASE.registry;
catch
    return;
end
if ~isfield(reg, 'SUBJ'), return; end
allSubjKeys = string(fieldnames(reg.SUBJ))';
if isempty(allSubjKeys), return; end

% ── Determine selected subjects from controlPanel averagingSelection ──────
selectedSubjKeys = {};
try
    avgSel  = nexon.console.BASE.controlPanel.averagingSelection;
    subjAll = avgSel.selKeys.subj;           % all subject strings
    subjIdx = avgSel.selections.subj;        % selected indices (may be multi-select)
    selSubjs = string(subjAll(subjIdx));     % selected subject name(s)
    for i = 1:numel(selSubjs)
        k = sprintf('subj_%s', strrep(char(selSubjs(i)), '-', '_'));
        if ismember(string(k), allSubjKeys)
            selectedSubjKeys{end+1} = k; %#ok<AGROW>
        end
    end
catch
end
% Fall back to first registry subject if nothing resolved
if isempty(selectedSubjKeys)
    selectedSubjKeys = {char(allSubjKeys(1))};
end

% ── Load and combine regMaps from all selected subjects ───────────────────
regMap = [];
for i = 1:numel(selectedSubjKeys)
    try
        rm = reg.SUBJ.(selectedSubjKeys{i}).regMap;
        if isempty(regMap)
            regMap = rm;
        else
            regMap = vertcat(regMap, rm);
        end
    catch
    end
end
if isempty(regMap), return; end

% ── Route by axis keyword ─────────────────────────────────────────────────
% Normalise: strip leading 'region' prefix so 'regionDropout' → 'dropout'
axID = lower(char(axisID));
axID = regexprep(axID, '^region', '');
switch axID
    case 'dropout'
        [colors, anyHit] = colorByRegionName(regMap, string(axisVals));
    case 'chans'
        [colors, anyHit] = colorByChannel(regMap, double(axisVals));
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
        for i = 1:nVals
            ch  = chanVals(i);
            hit = find(cellfun(@(c) ismember(ch, double(c)), regMap.channel), 1);
            if ~isempty(hit)
                colors(i,:) = hexToRGB(regMap.color, hit);
                anyHit = true;
            end
        end
    catch
        colors = [];
    end
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
