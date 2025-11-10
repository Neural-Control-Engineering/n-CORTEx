classdef nexObj_smoother < handle
    properties
        classID = "smth"
        nexon
        DF
        DF_postOp
        cfg
        Figure
    end
    methods
        function nexObj = nexObj_smoother(nexon, DF, smoothFcn)
            nexObj.nexon=nexon;
            nexObj.DF = DF;            
            % nexObj.cfg.opCfg.fcn = smoothFcn;
            nexObj.cfg.opCfg = nex_generateCfgObj(smoothFcn);                 %% DF
            % nexObj.cfg.opCfg.entryParams = extractMethodCfg(rmExtension(func2str(smoothFcn)));
            nexObj.DF_postOp = smooth_ASLS(nexObj.DF, nexObj.cfg.opCfg.entryParams);
            nexFigure_smoother(nexObj);
        end

        function updateScope(nexObj)
            nexObj.operate();
            nexObj.visualize();
        end

        function visualize(nexObj)
            nexVisualization_smoother(nexObj);
        end        
        function operate(nexObj)
            nexObj.DF_postOp = nexObj.cfg.opCfg.fcn(nexObj.DF, nexObj.cfg.opCfg.entryParams);
        end
    end
end