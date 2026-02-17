classdef nexObj_poolMap < handle
    properties
        Parent
        updateFcn=[];
        axID
        mapID
        divsPerBin=1;
        binType
        binTypes
        Map
        source_Map
        bins
        spans
        colors
    end

    methods 

        function poolMap = nexObj_poolMap(Parent, Map, source, axID, mapID)
            poolMap.Parent = Parent;
            poolMap.Map = Map;
            poolMap.axID = axID;
            poolMap.mapID = mapID;            
            poolMap.binTypes = [axID; mapID];
            poolMap.source_Map = source;        
        end

        function [binEdges, binIDs] = getBinEdges(poolMap, axis)
            switch poolMap.binType
                case poolMap.axID
                    regions = convertCharsToStrings(poolMap.Map.region)';
                    edges = ([size(regions,2) - ([1, find(~strcmp(regions(1:end-1), regions(2:end))) + 1]-1),0])';
                    % impute by divisons per bin
                    edgeCmp = num2cell([edges(1:end-1), edges(2:end)],2);
                    edgeSubDivs = cellfun(@(row) flip(round(linspace(row(2), row(1),poolMap.divsPerBin+1)',"TieBreaker","fromzero"),1), edgeCmp, "UniformOutput", false);
                    binEdges = flip(unique(cat(1,edgeSubDivs{:})),1);
                    % get binIDs
                    binIDs = regions(binEdges(binEdges~=0))';                
                    binEdges = flip(binEdges,1);
                case poolMap.mapID
                    nSteps = ceil((axis(end) - axis(1)) / poolMap.divsPerBin);                    
                    binEdges = round(linspace(axis(1), nSteps * poolMap.divsPerBin, nSteps))';                    
                    binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)],2);                    
                    binIDs = cellfun(@(idRange) sprintf("%d--%d",idRange(1),idRange(2)),binIDs_nums,"UniformOutput",true);                    
            end            
        end

        function updateScope(poolMap)
            if ~isempty(poolMap.updateFcn)
                poolMap.updateFcn(poolMap);
            end
        end

    end
end