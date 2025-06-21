classdef nexObj_spectroScope < handle
        properties
            classID
            nexon
            Parent
            Partners
            Children
            Origin
            DF
            DF_postOp
            dfID_source
            dfID_target
            preBufferLen
            Fs
            Figure
            compCfg
            opCfg
            visCfg
            aniCfg
            pMap_freqs
            pMap_chans
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
            function  nexObj = nexObj_spectroScope(nexon, Partner, Parent, opFcn)
                nexObj.classID = "spscp";
                nexObj.nexon = nexon;
                nexObj.Parent = Partner.Parent;                
                % obj.Partner = Partner;
                % Parent.Children.(("spectroScope1")) = obj;
                nexObj.Partners = struct;
                nexObj.Partners.(Partner.classID) = Partner;
                nexObj.Children = struct;
                nexObj.DF = Partner.DF_postOp;
                nexObj.DF_postOp = [];
                nexObj.preBufferLen = 3.5;
                nexObj.Fs = 500;
                % computation function
                nexObj.compCfg.fcn = str2func("nexCompute_spectroScope");
                nexObj.compCfg.entryParams = extractMethodCfg('nexCompute_spectroScope');
                % operation function
                nexObj.opCfg.opFcn = opFcn;
                nexObj.opCfg.entryParams = extractMethodCfg(func2str(opFcn));
                % visualization function
                nexObj.visCfg.visFcn =  str2func('nexVisualization_spectroScope');
                nexObj.visCfg.entryParams = extractMethodCfg(func2str(nexObj.visCfg.visFcn));
                % animation function
                nexObj.aniCfg.aniFcn = str2func('nexAnimate_spectroScope');
                nexObj.aniCfg.entryParams = extractMethodCfg(func2str(nexObj.aniCfg.aniFcn));
                nexObj.frameBuffer.compArgs = nexObj.compCfg.entryParams;                
                nexObj.isOnline = 0;
                nexObj.isStatic = 1;
                % Pooling config
                nexObj.pMap_freqs = poolMap_freqs(nexObj.nexon.console.BASE.params.bands,[]);
                nexObj.pMap_chans = poolMap_chans(nexObj.Parent.regMap,[]);
                % obj.pltTimer = timer("ExecutionMode","fixedRate","BusyMode","drop","Period",0.1,"TimerFcn",@(~,~)animate(obj, nexon));
                nexObj.isPlay=0;
                nexObj = nexFigure_spectroScope(nexon, nexObj);
                nexObj.dfID = sprintf("%s",func2str(opFcn));
            end

            function updateScope(nexObj)
                % disp("spectroScope update method incomplete");
                nexUpdate_spectroScope(nexObj);
                nex_updateChildren(nexObj.nexon, nexObj);
            end

            function reportAverage(nexObj, selIdx)
                % summarize with O-scores, spec params stats, etc.
            end

            function storeAverage(nexObj, DF_avg)
            end

            function scaleAnalysis(nexObj)

            end

            function visualize(nexObj)
            end

            function animate(nexObj)
            end
            
        end
end