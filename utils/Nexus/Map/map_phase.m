classdef map_phase < handle
    properties
        axID = "phase"
        Map
        source_Map        
    end

    methods
        function mapObj = map_phase(phaseMap, source, list_phases)
            if isempty(list_phases) & ~isempty(phaseMap)
                mapObj.Map = phaseMap;
            else
                mapObj.Map = nexGenerate_phaseMap(list_phases);
            end
            mapObj.source_Map = source;
        end
    end
end