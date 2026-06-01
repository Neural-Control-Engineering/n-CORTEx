classdef nexObj_poolMap_freqs< nexObj_poolMap
    methods
        function pMap = nexObj_poolMap_freqs(Parent, Map, source, axID, mapID)
                pMap = pMap@nexObj_poolMap(Parent, Map, source, axID, mapID);
        end
        % function [binEdges, binIDs] = getBinEdges(pMap)
        %     switch pMap.binType
        %         case "band"
        %             bands = poolMap.Map;
        %             bandNames = fieldnames(bands);
        %             % operation formatting
        %             bandNames = cellfun(@(bN) string(bN), bandNames,"UniformOutput",false);
        %             bandTable = struct2table(bands);
        %             edges = table2cell(bandTable)';
        %             % bandLUT = cellfun(@(row, bandName) repmat(bandName,[(row(2)-row(1)+1),1]), edges, bandNames,"UniformOutput",false);
        %             bandLUT = cellfun(@(row, bandName) repmat(bandName,[(row(2)-row(1)),1]), edges, bandNames,"UniformOutput",false);
        %             bandLUT = cat(1,bandLUT{:});
        %             % subdivisions
        %             edgeSubDivs = cellfun(@(row) flip(round(linspace(row(2), row(1),poolMap.divsPerBin+1)',"TieBreaker","fromzero"),1), edges, "UniformOutput", false);
        %             % edgeSubDivs = cellfun(@(row) flip((linspace(row(2), row(1),poolMap.divsPerBin+1)'),1), edgeCmp, "UniformOutput", false);
        %             binEdges = (unique(cat(1,edgeSubDivs{:})));     
        %             binIDs = bandLUT(binEdges(1:end-1)+1);
        %         case "freq"
        %             [binEdges, binIDs] = nexOp_getBinEdges(axis, pMap.divsPerBin);
        %     end            
        % end
    end
end