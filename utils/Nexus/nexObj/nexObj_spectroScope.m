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
            map_specs
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
            function  nexObj = nexObj_spectroScope(nexon, Partner, opFcn)
                nexObj.classID = "spscp";
                nexObj.nexon = nexon;
                nexObj.Parent = Partner.Parent;                
                nexObj.nexon.console.BASE.nexObjs.spscp_1=nexObj;
                % obj.Partner = Partner;
                % Parent.Children.(("spectroScope1")) = obj;
                nexObj.Partners = struct;
                nexObj.Partners.(Partner.classID) = Partner;
                nexObj.Children = struct;
                nexObj.DF = Partner.DF_postOp;
                nexObj.DF_postOp = [];
                nexObj.dfID_source = Partner.dfID_target;
                nexObj.preBufferLen = 3.5;
                nexObj.Fs = 500;
                % computation function
                nexObj.compCfg.fcn = str2func("nexCompute_spectroScope");
                nexObj.compCfg.entryParams = extractMethodCfg('nexCompute_spectroScope');
                % operation function
                nexObj.opCfg.opFcn = opFcn;
                nexObj.opCfg.entryParams = extractMethodCfg(func2str(opFcn));
                nexObj.dfID_target = func2str(opFcn);
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
                nexObj.map_specs = map_specs([]);
                % obj.pltTimer = timer("ExecutionMode","fixedRate","BusyMode","drop","Period",0.1,"TimerFcn",@(~,~)animate(obj, nexon));
                nexObj.isPlay=0;
                nexObj = nexFigure_spectroScope(nexObj);
                nexObj.dfID_target= sprintf("%s",func2str(opFcn));
            end

            function updateScope(nexObj)
                % disp("spectroScope update method incomplete");
                nexUpdate_spectroScope(nexObj);
                nex_updateChildren(nexObj.nexon, nexObj);
            end

            function reportAverage(nexObj, selIdx)
                % summarize with O-scores, spec params stats, etc.                
                % using mean and weldord's method
                % iterator over each selIdx                
                %% RETRIEVAL
                DFID = sprintf("%s--%s",nexObj.classID,func2str(nexObj.opCfg.opFcn));                
                % dfCol = nexObj.nexon.console.BASE.DTS.(dfTag);
                % tCol = nexObj.nexon.console.BASE.DTS.(tTag);            
                %% MASK SELECTION
                if isempty(selIdx)
                    S = nex_returnSelectionMask(nexObj.nexon.console.BASE.controlPanel.averagingSelection);
                    maskIdx = nex_applySelectionMask(nexObj.nexon.console.BASE.DTS,S);                   
                else                    
                    maskIdx = selIdx;
                end
                %% RETRIEVAL
                maskIdx_nums = find(maskIdx==1);
                DF_sel = dtsIO_readDF(nexObj.nexon,DFID,maskIdx_nums);
                for i = 1:size(DF_sel,1)
                    DF_i = DF_sel{i};
                    %% FORMATTING                
                    DF_form = formatSpecs(DF_i,"timeFrequency",nexObj.map_specs.Map);
                    %% ALIGNMENT (skip for now)
                    % nexAlign_signals()
                    DF_aligned = DF_form;
                    %% AVERAGING/STD
                end
                %% POOLING
                [DF_avg_pooled.df, binIDs_chans, binTicks_chans] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_chans,1, DF_avg.ax.chans), DF_avg.df,"UniformOutput",false);
                [DF_avg_pooled.df, binIDs_freqs, binTicks_freqs] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_freqs,2, DF_avg_pooled.ax.f), DF_avg_pooled.df,"UniformOutput",false);
                [DF_std_pooled.df, binIDs_chans, binTicks_chans] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_chans,1, DF_std.ax.chans), DF_std.df,"UniformOutput",false);
                [DF_std_pooled.df, binIDs_freqs, binTicks_freqs] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_freqs,2, DF_std_pooled.ax.f), DF_std_pooled.df,"UniformOutput",false);

                %% STORE RESULT 
                nex_storeAverage(nexObj, nexObj.DF_postOp);
                %% VISUALIZATION
                nexObj.visualize();

            end

            function storeAverage(nexObj, DF_avg)
            end

            % function formatSpecs(nexObj, format)
            %     switch format
            %         case "time-frequency"
            %         case "parametric"
            %     end
            % end

            function compute(nexObj)
                compArgs = nexObj.compCfg.entryParams;
                nexObj.DF_postOp = nexObj.compCfg.fcn(nexObj, compArgs);
            end

            function scaleAnalysis(nexObj)
                dfIDsource = sprintf("%s--%s",nexObj.Partners.chg.classID,nexObj.dfID_source);
                % dfIDtarget = sprintf("%s--%s",nexObj.classID,func2str())
                % nexAnalysis_scaleAnalysis(nexObj.nexon, nexObj.classID, nexObj.opCfg.opFcn, nexObj.opCfg.entryParams, dfIDsource, nexObj.dfID_target,[]);
                nexAnalysis_scaleAnalysis(nexObj.nexon, nexObj.classID, nexObj.opCfg.opFcn, nexObj.opCfg.entryParams, dfIDsource, [] ,[]);
            end

            function exportTrainingDataset(nexObj)
                
            end

            function visualize(nexObj)
            end

            function animate(nexObj)
            end
            
        end
end