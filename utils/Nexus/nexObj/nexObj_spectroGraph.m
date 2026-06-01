classdef nexObj_spectroGraph < handle
        properties
            classID = "spgph"
            preBuffLen
            nexon
            Origin
            Parent
            DF
            DF_postOp
            dfID_source
            dfID_target
            opCfg=struct;
            visCfg=struct;
            Figure
            UserData=struct;
            chanSel=1;
            freqSel=1;
        end

        methods 
            function nexObj = nexObj_spectroGraph(nexon, spectroGram, DF, opFcn, visFcn)                                
                nexObj.Origin = spectroGram.Origin;
                nexObj.preBuffLen = spectroGram.preBuffLen;
                if isempty(nexon)
                    nexObj.nexon = nexObj.Origin.nexon;
                else
                    nexObj.nexon = nexon;
                end
                nexObj.Parent = spectroGram;
                if isempty(DF)
                    nexObj.DF = nexObj.Parent.DF_postOp;
                else
                    nexObj.DF = DF;
                end
                nexObj.DF_postOp.df=[];
                nexObj.DF_postOp.ax=[];
                % nexObj.dataFrame=dataFrame;
                nexObj.dfID_source=nexObj.Parent.dfID_target;                                
                % nexObj.opCfg = extractCfg(opFcn);
                if isempty(visFcn)
                    visFcn = str2func("nexVisualization_spectroGraph");
                end
                nexObj.visCfg = extractCfg(visFcn);
                nexObj.visCfg.visFcn = visFcn;
                % generate figure
                nexFigure_spectroGraph(nexObj);
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

            % function reportAverage(nexObj)
            %     % visualize DF (plus stats)
            % end
            function operate(nexObj)
                opArgs = nexObj.opCfg.entryParams;
                nexObj.DF_postOp = nexObj.opCfg.opFcn(nexObj.DF, opArgs);
            end

            function visualize(nexObj)
                visArgs = nexObj.visCfg.entryParams;
                nexObj.visCfg.visFcn(nexObj, visArgs);
            end

            function updateScope(nexObj, nexon)
                nexUpdate_spectroGraph(nexObj);
                nexObj.visualize();
            end

            function value = getVal_tMarker(nexObj, t_clock)
                t = nexObj.DF.ax.t;
                [minVal, idx] = min(abs(t - t_clock));
                value = t(idx);
            end
        end
end