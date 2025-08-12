classdef poolMap_time < handle
    properties
        axID = "t"
        divsPerBin=1
        binType="linear"
        binTypes=["linear","event"]
        Map
        source_Map=[]
        bins
        spans
        colors
    end
    methods
        function poolMap = poolMap_time(IDs_events, source)            
            poolMap.Map = nexGenerate_eventMap(IDs_events);
        end
        function [binEdges, binIDs] = getBinEdges(poolMap, axis)
            switch poolMap.binType
                case "event"
                    % bin by before/after selected event
                case "linear"
                    binEdges = [axis(1):poolMap.divsPerBin:axis(end)]';
                    % channel ranges
                    binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)-1],2);
                    binIDs = cellfun(@(idRange) sprintf("%d--%d",idRange(1),idRange(2)),binIDs_nums,"UniformOutput",false);
            end
        end
    end
end
