classdef nexObj_spectroScope < handle
        properties
            classID
            nexon
            Parent
            Partners
            Children
            Origins
            DF
            DF_postOp
            dfID
            preBufferLen
            Fs
            Figure
            compCfg
            opCfg
            visCfg
            aniCfg
            UserData
            isOnline
            isStatic
            pltTimer
            isPlay
            isWriteSelected
            frameBuffer
        end

        methods
            % Constructor
            function  obj = nexObj_spectroScope(nexon, Parent, opFcn)
                obj.classID = "sps";
                obj.nexon = nexon;
                obj.Parent = Parent;
                Parent.Children.(("spectroScope1")) = obj;
                obj.Partners = struct;
                obj.Children = struct;
                obj.DF = Parent.DF_postOp;
                obj.DF_postOp = struct;
                obj.preBufferLen = 3.5;
                obj.Fs = 500;
                % computation function
                obj.compCfg.compFcn = str2func("nexCompute_spectroScope");
                obj.compCfg.entryParams = extractMethodCfg('nexCompute_spectroScope');
                % operation function
                obj.opCfg.opFcn = opFcn;
                obj.opCfg.entryParams = extractMethodCfg(func2str(opFcn));
                % visualization function
                obj.visCfg.visFcn =  str2func('nexVisualization_spectroScope');
                obj.visCfg.entryParams = extractMethodCfg(func2str(obj.visCfg.visFcn));
                % animation function
                obj.aniCfg.aniFcn = str2func('nexAnimate_spectroScope');
                obj.aniCfg.entryParams = extractMethodCfg(func2str(obj.aniCfg.aniFcn));
                obj.frameBuffer.compArgs = obj.compCfg.entryParams;                
                obj.isOnline = 0;
                obj.isStatic = 1;
                % obj.pltTimer = timer("ExecutionMode","fixedRate","BusyMode","drop","Period",0.1,"TimerFcn",@(~,~)animate(obj, nexon));
                obj.isPlay=0;
                % obj = nexFigure_spectroScope(nexon, obj);
                obj.dfID = sprintf("%s",func2str(opFcn));
            end

            function updateScope(obj, nexon)
                disp("spectroScope update method incomplete");
            end
            
        end
end