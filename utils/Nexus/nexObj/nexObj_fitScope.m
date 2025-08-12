classdef nexObj_fitScope < handle
    properties
        classID
        nexon        
        DF
        kernel
        params
        visCfg
        Figure
        Parent
        UserData
    end
    methods
        function nexObj = nexObj_fitScope()
        end

        function updateScope(nexObj)
            % re-compute df with given parameters
            nexObj.DF.df_fit = nexObj.kernel(nexObj.params);
            % nexObj.DF.df = [];
            nexObj.visualize();
        end

        function visualize(nexObj)
            visArgs = nexObj.visCfg.entryParams;
            nexVisualization_fitScope(nexObj, visArgs);
        end
    
    end
end