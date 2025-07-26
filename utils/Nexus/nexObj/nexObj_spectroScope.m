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
            frameNum
        end

        methods
            % Constructor
            function  nexObj = nexObj_spectroScope(nexon, Partner, opFcn)
                nexObj.classID = "spscp";
                nexObj.nexon = nexon;
                nexObj.Parent = Partner.Parent;
                % turn into add Parent fcn for shank later
                nexObj.Parent.scope.(sprintf("%s_1",nexObj.classID))=nexObj;
                nexObj.Origin = Partner.Origin;
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
                t_min = min(cellfun(@(DF) size(DF.df,3), DF_sel, "UniformOutput", true));
                % slrt alignment selection
                S_slrt = nex_returnSelectionMask(nexObj.nexon.console.SLRT.signals.eventAlignmentSelection);
                alignColTags = split(S_slrt.events,"_");                
                tColID = sprintf("%s_aligned_%s_time",alignColTags(1),alignColTags(2));
                tCol_slrt = dtsIO_readDF(nexObj.nexon,tColID,maskIdx_nums);                
                % t_max =
                % DF_mean = DF_sel{1};
                n_avg = size(DF_sel,1);
                n_inc = 1; % incremented n
                for i = 1:n_avg
                    disp(i)
                    DF_i = DF_sel{i};
                    DF_i.df = DF_i.df(:,:,1:t_min);
                    %% FORMATTING                
                    DF_form = formatSpecs(DF_i,"timeFrequency",nexObj.map_specs.Map);
                   %% ALIGNMENT (skip for now)                    
                    t_slrt = tCol_slrt{i}.time;
                    fs_slrt = nexObj.nexon.console.SLRT.signals.UserData.Fs;
                    t_preBuff = nexObj.preBufferLen;
                    DF_aligned = DF_form;                    
                    % [dfCol_aligned, tCol_aligned] = nexAlign_signals(DF_form.df, DF_form.ax.t, t_slrt, fs_slrt, t_preBuff,3);            
                    [df_aligned, t_aligned] = structfun(@(df) nexAlign_signals(df, DF_form.ax.t, {t_slrt}, fs_slrt, t_preBuff, 3), DF_aligned.df, "UniformOutput", false);
                    DF_aligned.df = structfun(@(df) df{1,1}, df_aligned, "UniformOutput", false);
                    DF_aligned.ax.t = t_aligned.OFF{1,1};
                    % trim t-axis
                    % POOL
                    DF_apForm = DF_aligned;
                    [DF_apForm.df, binIDs_chans, binTicks_chans] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_chans, 1, DF_aligned.ax.chans), DF_aligned.df, "UniformOutput", false);
                    [DF_apForm.df, binIDs_freqs, binTicks_freqs] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_freqs, 2, DF_apForm.ax.f), DF_apForm.df, "UniformOutput", false);
                    if i ==1 % copy as an accumulator
                        DF_avg = DF_apForm;                        
                        DF_avg.df = structfun(@(x) zeros(size(x)), DF_avg.df,"UniformOutput",false);
                        DF_std_pre = DF_avg;
                        % [DF_avg, DF_std] = cellfun(@(df_acc_avg, df_acc_std, n_avg), nexAccumulate_average(), "UniformOutput", false);                        
                    end                   
                    %% AVERAGING/STD
                    [DF_avg, DF_std_pre] = nexAccumulate_average(DF_avg, DF_std_pre, DF_apForm, n_inc);                    
                    n_inc = n_inc + 1;
                end                
                % post welford's std-derivation
                DF_var=DF_std_pre; 
                DF_std=DF_std_pre;
                % variance                     
                DF_var.df = structfun(@(df) df ./ (n_avg-1), DF_std_pre.df, "UniformOutput", false);
                % standard-deviation
                DF_std.df = structfun(@(df) sqrt(df), DF_var.df, "UniformOutput", false);                   
                % POOLING
                % pool-masking
                % nanMask = (DF_avg.df.CF==0 & DF_avg.df.PW == 0 & DF_avg.df.BW ==0);
                % DF_avg_mask = DF_avg;
                % DF_std_mask = DF_std;
                % DF_avg_mask.df = structfun(@(df) nex_maskReplace(df, nan, nanMask), DF_avg_mask.df, "UniformOutput", false);
                % DF_std_mask.df = structfun(@(df) nex_maskReplace(df, nan, nanMask), DF_std_mask.df, "UniformOutput", false);
                % pool operation
                % DF_avg_pooled = DF_avg_mask;
                % DF_std_pooled = DF_std_mask;
                % [DF_avg_pooled.df, binIDs_chans, binTicks_chans] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_chans,1, DF_avg_mask.ax.chans), DF_avg_mask.df,"UniformOutput",false);
                % [DF_avg_pooled.df, binIDs_freqs, binTicks_freqs] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_freqs,2, DF_avg_mask.ax.f), DF_avg_pooled.df,"UniformOutput",false);
                % [DF_std_pooled.df, binIDs_chans, binTicks_chans] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_chans,1, DF_std_mask.ax.chans), DF_std_mask.df,"UniformOutput",false);
                % [DF_std_pooled.df, binIDs_freqs, binTicks_freqs] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_freqs,2, DF_std_mask.ax.f), DF_std_pooled.df,"UniformOutput",false);
                DF_sem= DF_std;
                DF_sem.df = structfun(@(df) df ./ sqrt(n_avg), DF_sem.df, "UniformOutput", false);
                DF_avg.ax.chans= binTicks_chans;
                DF_avg.ax.f = binTicks_freqs;
                DF_sem.ax.chans = binTicks_chans;
                DF_sem.ax.f = binTicks_freqs;
                %% STORE RESULT                
                nexObj.DF_postOp = DF_avg;
                nexObj.DF_postOp.sem = DF_sem.df;
                avgCfg_sel = nexObj.nexon.console.BASE.controlPanel.averagingSelection.selections;
                avgCfg_keys = nexObj.nexon.console.BASE.controlPanel.averagingSelection.selKeys;
                avgCfg = nex_structfun2(@(cfgSel, cfgKey) cfgKey(cfgSel), avgCfg_sel, avgCfg_keys);
                nexObj.DF_postOp.avgCfg = avgCfg;                
                nex_storeAverage(nexObj, nexObj.DF_postOp);
                %% VISUALIZATION
                nexObj.visualize();
                nex_updateChildren(nexObj.nexon, nexObj);

            end

            % function storeAverage(nexObj, DF_avg)
            % end

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

            function nexport(nexObj)
                labelIDs = [];
                nexportArgs = extractMethodCfg('nexport_ML');
                exportFcn = str2func("expIO_rtSpec");
                DFID_target = sprintf("%s--%s",nexObj.classID, nexObj.dfID_target);
                DFID_source = sprintf("%s--%s",nexObj.Partners.chg.classID, nexObj.dfID_source);
                nexport_ML(nexObj.nexon, DFID_target, DFID_source, labelIDs, exportFcn, nexportArgs)
            end

            function addChild(nexObj)
                nexObj_spgphSP = nexObj_spectroGraph_specs([],nexObj,[],[],[]);
                nexObj.Children.(sprintf("%s_1",nexObj_spgphSP.classID))=nexObj_spgphSP;
            end

            function exportTrainingDataset(nexObj)
                
            end

            function visualize(nexObj)
            end

            function animate(nexObj)
            end
            
        end
end