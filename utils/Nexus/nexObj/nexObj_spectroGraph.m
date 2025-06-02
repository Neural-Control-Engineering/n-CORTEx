classdef nexObj_spectroGraph < handle
        properties
            classID = "spgph"
            nexon
            Parent
            DF
            DF_postOp
            dfID
            opCfg=struct;
            visCfg=struct;
            Figure
            UserData=struct;
            chanSel=1;
            freqSel=1;
        end

        methods (Static)
            function nexObj = nexObj_spectroGraph(nexon, spectroGram, dataFrame, dfID, opFcn, visFcn)
                nexObj.nexon = nexon;
                nexObj.Parent = spectroGram;
                nexObj.DF = nexObj.Parent.DF_postOp;
                nexObj.DF_postOp.df=[];
                nexObj.DF_postOp.ax=[];
                nexObj.dataFrame=dataFrame;
                nexObj.dfID=dfID;                
                nexFigure_spectroGraph(nexObj);
                % nexObj.opCfg = extractCfg(opFcn);
                if isempty(visFcn)
                    visFcn = str2func("nexVisualization_spectroGraph");
                end
                nexObj.visCfg = extractCfg(visFcn);
                % operation function
                % if ~isempty(opFcn)
                %     nexObj.opCfg.opFcn = opFcn;
                % else
                %     nexObj.opCfg = struct;
                % end
                % nexObj.opCfg = extractCfg(opFcn);
                % visualization function
                % nexObj.visCfg = extractCfg(visFcn);
            end
        end
end