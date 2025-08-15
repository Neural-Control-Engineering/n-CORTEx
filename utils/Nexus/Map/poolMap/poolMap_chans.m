classdef poolMap_chans < handle
    properties
        axID = "chans"
        divsPerBin=1 % number of bins per pool
        binType = "region"
        binTypes = ["chan", "region"]
        Map        
        source_Map
        bins
        spans
        colors
    end
    
    methods
        function poolMap = poolMap_chans(regMap, source)
            poolMap.Map = regMap;
            poolMap.source_Map = source;
        end

        function [binEdges, binIDs] = getBinEdges(poolMap, axis)
            % if isempty(poolMap.regMap)
            switch poolMap.binType
                case "region"
                    regions = convertCharsToStrings(poolMap.Map.region)';
                    edges = ([size(regions,2) - ([1, find(~strcmp(regions(1:end-1), regions(2:end))) + 1]-1),0])';
                    % impute by divions per bin
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
                case "chan"
                    % binEdges = round(linspace(axis(1), axis(end), poolMap.divsPerBin*(axis(end)-axis(1))))';
                    % binEdges = [axis(1):poolMap.divsPerBin:axis(end)]';
                    nSteps = ceil((axis(end) - axis(1)) / poolMap.divsPerBin);
                    % binEdges = round(linspace(axis(1), axis(1) + nSteps * poolMap.divsPerBin, nSteps + 1))';
                    binEdges = round(linspace(axis(1), nSteps * poolMap.divsPerBin, nSteps))';
                    % channel ranges
                    binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)],2);
                    % binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)],2);
                    binIDs = cellfun(@(idRange) sprintf("%d--%d",idRange(1),idRange(2)),binIDs_nums,"UniformOutput",true);
                    % binIDs = flip(binIDs,1);
                    % binIDs = sprintf("%d--%d");
            end
        end

        function binTypes = getBinTypes(poolMap)
        end

        function poolCfgEntry
        end
    end
end