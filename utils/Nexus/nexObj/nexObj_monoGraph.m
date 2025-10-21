classdef nexObj_monoGraph < handle
    properties
        classID = "mgph"
        DF
        DF_postOp
        dfID_source
        nexon
        polyGraph
        Parent
        Origin
        Figure
        cfg=struct
    end

    methods
        function nexObj = nexObj_monoGraph(Parent, Origin, nexon, opCfgFcn)
            % resolve time-resolved recordings over varied dimensions
            % (channel, frequency, etc.)
            if isempty(Parent) % standalone monograph, attach to nexon
                nexObj.nexon = nexon;
                df = grabDataFrame(nexon, "lfp",[]);
                df_t = grabDataFrame(nexon,"t_lfp",[]);
                nexObj.DF = lfp2DF(df, df_t);                
            else
                nexObj.Parent = Parent;
                nexObj.dfID_source = sprintf("nexObj_%s",Parent.classID);
                if isempty(Origin)
                    nexObj.Origin = Parent.Origin;
                else
                    nexObj.Origin = Origin;
                end
                nexObj.nexon = Parent.nexon;
                nexObj.Parent.Children.(nexObj.classID) = nexObj;
                nexObj.DF = Parent.DF_postOp;
            end
            % CONFIG
            if ~isempty(opCfgFcn)
                nexObj.cfg.opCfg=nex_generateCfgObj(opCfgFcn);                
                nexObj.operate();
            else
                nexObj.cfg.opCfg=[];
                nexObj.DF_postOp = nexObj.DF;
            end
            % Axis pointer
            nexObj.DF_postOp = nex_initAxisPointer_v2(nexObj.DF_postOp);
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_monoGraph"));                        
            % Inherit DF
            nexObj.buildFigure();
        end

        function visualize(nexObj)
            visArgs = nexObj.cfg.visCfg.entryParams;
            nexVisualization_monoGraph(nexObj, visArgs);
        end

        function buildFigure(nexObj)
            nexFigure_monoGraph(nexObj);
        end

        function updateScope(nexObj)
            % inherit new DF
            nexObj.DF = nexObj.Parent.DF_postOp;
            % operate
            nexObj.operate();
            % visualize
            nexObj.visualize();
        end

        function operate(nexObj)
            % reassign the pointer elements
            % operate
            if isfield(nexObj.DF_postOp,'ptr')
                oldPtr = nexObj.DF_postOp.ptr;
            else
                oldPtr = [];
            end
            if ~isempty( nexObj.cfg.opCfg)
                opArgs = nexObj.cfg.opCfg.entryParams;
                nexObj.DF_postOp = nexObj.cfg.opCfg.opFcn(nexObj.DF, opArgs);
            else
                nexObj.DF_postOp = nexObj.DF;
            end            
           % preserve ptrObj
            if ~isempty(oldPtr)
                nexObj.DF_postOp = nex_initAxisPointer_v2(nexObj.DF_postOp);
                newPtr = nexObj_ptr(nexObj.DF_postOp.ptr);
                f = fieldnames(newPtr);
                for i = 1:numel(f)
                    oldPtr.(f{i}) = newPtr.(f{i});
                end
                nexObj.DF_postOp.ptr = oldPtr;
            end            
        end
    end
   
end