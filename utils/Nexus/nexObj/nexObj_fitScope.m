classdef nexObj_fitScope < handle
    properties
        classID="fitScp"
        nexon        
        DF
        DF_postOp
        fitCfg                
        mlCfg % 
        Figure
        Parent
        UserData
        ModelObj
    end
    methods
        function nexObj = nexObj_fitScope(Parent, DF, fitFcn)
            nexObj.Parent = Parent;
            nexObj.DF = DF;
            nexObj.DF_postOp = DF;
            % fit method configuration
            nexObj.fitCfg.kernel=str2func(fitFcn);
            nexObj.fitCfg.entryParams=extractMethodCfg(fitFcn);
            nexObj.DF.df_fit = nexObj.fitCfg.kernel(nexObj.DF.ax, nexObj.fitCfg.entryParams);
            % machine learning configuration (optional)
            nexObj.mlCfg.DSCfg.numFolds = 5;            
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
            % nexObj.UserData.isSave=1;
            % uiresume(nexObj.Figure.fh);
            DF_smp = nexObj.DF_postOp;
            args.sampleAddress.sessionLabel = sessionLabel;
            args.sampleAddress.trialNum = trialNum;
            args.DSCfg = nexObj.mlCfg.DSCfg;
            FID = nexObj.UserData.FID;
            MLIO_writeDS_rtspec(nexObj.nexon.console.BASE.params, DF_smp, FID, args);
            % increment pointer (OR switch to next DF?)
        end

        function discardFit(nexObj)            
            % signal discard
            % nexObj.UserData.isSave=0;
            % uiresume(nexObj.Figure.fh)
            % switch to next signal (within DF)
            % increment pointer 
            nexObj.ptr_scope = nexObj.ptr_scope+1;
        end
    
    end
end