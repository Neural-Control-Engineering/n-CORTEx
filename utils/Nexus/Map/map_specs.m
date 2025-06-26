classdef map_specs< handle
    properties
        axID = "specs"     
        Map        
    end

    methods
        function mapObj = map_specs(specsMap)
            if isempty(specsMap)
                paramIDs = ["OFF","EXP","PW","BW","CF","ERR","RSQ"];
                mapObj.Map = nexGenerate_specsMap(paramIDs);
            else
                mapObj.Map = specsMap;
            end
        end
    end

end