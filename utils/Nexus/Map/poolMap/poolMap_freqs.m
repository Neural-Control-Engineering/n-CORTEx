classdef poolMap_freqs < handle
    properties
        axID = "f"
        divsPerBin=1
        binType="band"
        binTypes=["freq","band"];    
        Map        
        source_Map
        bins
        spans
        colors
    end
    
    methods
        function poolMap = poolMap_freqs(bands, source)
            poolMap.Map = bands;
            poolMap.source_Map = source;
        end

        function [binEdges, binIDs] = getBinEdges(poolMap, axis)
            switch poolMap.binType
                case "band"
                    bands = poolMap.Map;
                    bandNames = fieldnames(bands);
                    % operation formatting
                    bandNames = cellfun(@(bN) string(bN), bandNames,"UniformOutput",false);
                    bandTable = struct2table(bands);
                    edges = table2cell(bandTable)';
                    % bandLUT = cellfun(@(row, bandName) repmat(bandName,[(row(2)-row(1)+1),1]), edges, bandNames,"UniformOutput",false);
                    bandLUT = cellfun(@(row, bandName) repmat(bandName,[(row(2)-row(1)),1]), edges, bandNames,"UniformOutput",false);
                    bandLUT = cat(1,bandLUT{:});
                    % subdivisions
                    edgeSubDivs = cellfun(@(row) flip(round(linspace(row(2), row(1),poolMap.divsPerBin+1)',"TieBreaker","fromzero"),1), edges, "UniformOutput", false);
                    % edgeSubDivs = cellfun(@(row) flip((linspace(row(2), row(1),poolMap.divsPerBin+1)'),1), edgeCmp, "UniformOutput", false);
                    binEdges = (unique(cat(1,edgeSubDivs{:})));     
                    binIDs = bandLUT(binEdges(1:end-1)+1);
                case "freq"
                    binEdges = [axis(1):poolMap.divsPerBin:axis(end)]';
                    % channel ranges
                    binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)-1],2);
                    binIDs = cellfun(@(idRange) sprintf("%d--%d",idRange(1),idRange(2)),binIDs_nums,"UniformOutput",true);
            end
        end

        function binTypes = getBinTypes(poolMap)
        end
    end
end