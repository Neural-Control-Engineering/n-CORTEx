function orderedRegions = nexOp_regionDepthOrder(nexon, regionNames)
% Canonical deep -> shallow order for a set of region names, driven by the
% atlas registry's per-channel depth column (regMap.Y, um from probe tip —
% 0 = deepest, increasing toward brain surface — see
% nexAtlas_loadRegMap.m). Pools regMap across ALL currently-selected
% subjects (nexOp_selectedSubjectsRegMap — same convention
% nex_axisColorFromRegistry.m uses for color lookup), so a multi-subject
% bar comparison gets one consistent order even if probe placement varies
% slightly per subject.
%
% Each region's depth is the mean Y across every channel/row mapped to it
% (pooled across subjects). A region name not found in the registry at all
% is appended at the end, in its original relative (encounter) order —
% never dropped, since nexStat_binSTAT still needs a slot for every value
% actually present in the data.
%
%   nexon       : root Nexon handle
%   regionNames : region name values actually present in the data being
%                 plotted (string/cellstr/categorical; duplicates fine)
%
%   orderedRegions : unique(regionNames), reordered deep -> shallow —
%                    string row vector

    orderedRegions = unique(string(regionNames(:))', 'stable');
    if isempty(orderedRegions), return; end

    regMap = nexOp_selectedSubjectsRegMap(nexon);
    if isempty(regMap), return; end

    try
        mapRegions = string(regMap.region);
        mapDepths  = double(regMap.Y);
        depth      = nan(size(orderedRegions));
        for i = 1:numel(orderedRegions)
            m = mapRegions == orderedRegions(i);
            if any(m)
                depth(i) = mean(mapDepths(m), 'omitnan');
            end
        end
        % Ascending sort puts smallest Y (deepest) first and pushes NaN
        % (not found in the registry) to the end automatically — no
        % special-casing needed for the "unknown region" fallback.
        [~, ord] = sort(depth);
        orderedRegions = orderedRegions(ord);
    catch
        orderedRegions = unique(string(regionNames(:))', 'stable');
    end
end
