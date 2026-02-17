classdef nexObj_poolMap_chans < nexObj_poolMap
    methods
        function pMap = nexObj_poolMap_chans(Parent, Map, source, axID, mapID)
                pMap = pMap@nexObj_poolMap(Parent, Map, source, axID, mapID);
        end
        function [binEdges, binIDs] = getBinEdges(pMap, axis)
            % if isempty(poolMap.regMap)
            switch pMap.binType
                case "region"
                    regions = convertCharsToStrings(poolMap.Map.region)';
                    edges = ([size(regions,2) - ([1, find(~strcmp(regions(1:end-1), regions(2:end))) + 1]-1),0])';
                    % impute by divisions per bin
                    edgeCmp = num2cell([edges(1:end-1), edges(2:end)],2);
                    edgeSubDivs = cellfun(@(row) flip(round(linspace(row(2), row(1),poolMap.divsPerBin+1)',"TieBreaker","fromzero"),1), edgeCmp, "UniformOutput", false);
                    % edgeSubDivs = cellfun(@(row) flip((linspace(row(2), row(1),poolMap.divsPerBin+1)'),1), edgeCmp, "UniformOutput", false);
                    binEdges = flip(unique(cat(1,edgeSubDivs{:})),1);
                    % regions_flipMatch = flip(regions,2)';                    
                    % get binIDs
                    % binIDs = regions_flipMatch(binEdges(binEdges~=0));                
                    binIDs = regions(binEdges(binEdges~=0))';                
                    binEdges = flip(binEdges,1);
                    % append channel ranges
                case "chans"
                    [binEdges, binIDs] = nexOp_getBinEdges(axis, pMap.divsPerBin);
            end
        end
    end
end