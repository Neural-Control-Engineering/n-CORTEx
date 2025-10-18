classdef nexObj_polyGraph < handle
    properties
        DF
        DF_postOp
        monoGraphs
        nexon
        Parent
        axCfg        
        Figure
    end

    methods
        function nexObj = nexObj_polyGraph(nexon, DF)
            nexObj.nexon = nexon;
            nexObj.DF = DF;
            nexObj.DF_postOp = DF;
            nexObj.buildFigure();
        end

        function buildFigure(nexObj)
            nexObj.Figure.fh = uifigure("Position",[100,1260,650,1250],"Color",[0,0,0]);   
            
        end

        function updateScope(nexObj)
        end

        function visualize(nexObj)
        end

        function reportAverage(nexObj)
        end

    end
end