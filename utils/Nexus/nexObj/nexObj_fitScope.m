classdef nexObj_fitScope < handle
    properties
        classID="fitScp"
        nexon        
        DF
        fitCfg                
        Figure
        Parent
        UserData
    end
    methods
        function nexObj = nexObj_fitScope(Parent, DF, fitFcn)
            nexObj.Parent = Parent;
            nexObj.DF = DF;
            nexObj.fitCfg.kernel=str2func(fitFcn);
            nexObj.fitCfg.entryParams=extractMethodCfg(fitFcn);
            nexObj.DF.df_fit = nexObj.fitCfg.kernel(nexObj.DF.ax, nexObj.fitCfg.entryParams);
            nexObj.Figure = nexFigure_fitScope(nexObj);
        end

        function updateScope(nexObj)
            % re-compute df with given parameters
            nexObj.DF.df_fit = nexObj.fitCfg.kernel(nexObj.DF.ax, nexObj.fitCfg.entryParams);
            % nexObj.DF.df = [];
            nexObj.visualize();
        end

        function visualize(nexObj)
            % visArgs = nexObj.fitCfg.entryParams;
            visArgs = struct;
            nexVisualization_fitScope(nexObj, visArgs);
        end

        function saveFit(nexObj)            
            % signal save to dataset
            nexObj.UserData.isSave=1;
            uiresume(nexObj.Figure.fh);
        end

        function discardFit(nexObj)            
            % signal discard
            nexObj.UserData.isSave=0;
            uiresume(nexObj.Figure.fh)
        end
    
    end
end