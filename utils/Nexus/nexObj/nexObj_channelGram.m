classdef nexObj_channelGram < handle
    properties
        classID
        nexon
        Parent
        Partners 
        Children % hold sub-Objs (e.g. spectrogram)
        Origins
        DF % df pre operation function (behavior depends on online or offline status); struct containing df and ax 
        DF_postOp % df post operation function (behavior depends on online or offline status); struct containint df and ax (and opCfg!?)
        dataFrame % This will hold any type of data, such as a struct     
        frameNum
        entryPanel
        dfID_source
        dfID % DTS df identifier (trial-wise)
        f % frequency axis
        t % time axis        
        preBufferLen
        Fs
        Figure % figure handle        
        compCfg
        exportCfg
        opCfg
        visCfg
        aniCfg
        poolCfg
        pMap_freqs
        pMap_chans
        UserData
        bPool        
        rtSpec
        isOnline
        isStatic
        pltTimer
        isPlay
        frameBuffer
    end
    
    methods
        % Constructor
        function nexObj = nexObj_channelGram(nexon, shank, dataFrame, dfID, opFcn, visFcn, aniFcn)
            nexObj.classID = "chg";
            nexObj.nexon = nexon;
            nexObj.nexon.console.BASE.nexObjs.chg_1=nexObj;
            nexObj.Parent = shank;
            nexObj.Partners = struct;
            nexObj.Children = struct;            
            nexObj.DF = struct;
            nexObj.DF_postOp = struct;
            nexObj.dataFrame=dataFrame;    
            nexObj.DF.df = dataFrame;
            nexObj.dfID = dfID; % dataframe column identifier
            nexObj.f = []; % frequency axis
            nexObj.t = []; % time axis            
            nexObj.preBufferLen = 3.5;
            nexObj.Fs = 500;
            nexObj.frameNum = 1; % time-wise frame (for animating or plotting)
            nexObj.frameBuffer.frames=[];
            nexObj.frameBuffer.frameIds=[];            
            nexObj.UserData = struct;
            nexObj.UserData.chanSel = 1;         
            % computation function
            nexObj.compCfg.compFcn = str2func("nexCompute_channelGram");
            nexObj.compCfg.entryParams = extractMethodCfg('nexCompute_channelGram');
            % export function
            nexObj.exportCfg.exportFcn = str2func("nexExport_channelGram");
            nexObj.exportCfg.entryParams = [];
            % operation function
            nexObj.opCfg.opFcn = opFcn;
            nexObj.opCfg.entryParams = extractMethodCfg(rmExtension(func2str(opFcn)));              
            nexObj.frameBuffer.opArgs = nexObj.opCfg.entryParams;
            % visualization function
            nexObj.visCfg.visFcn = visFcn;
            nexObj.visCfg.entryParams = extractMethodCfg(rmExtension(func2str(visFcn)));
            % animation function
            nexObj.aniCfg.aniFcn = aniFcn;
            nexObj.aniCfg.entryParams = extractMethodCfg(rmExtension(func2str(aniFcn)));      
            nexObj.frameBuffer.aniArgs = nexObj.aniCfg.entryParams;
            % segmentation/binning Cfg (configure binning of axes, for pooling ops))
            % nexObj.poolCfg.poolMaps.bands = nexon.console.BASE.params.bands;
            % nexObj.poolCfg.poolMaps.regions = nexObj.Parent.regMap;
            nexObj.pMap_freqs = poolMap_freqs(nexObj.nexon.console.BASE.params.bands,[]);
            nexObj.pMap_chans = poolMap_chans(nexObj.Parent.regMap,[]);
            % nexObj.poolCfg.ax.f.poolMaps.bands = nexFormat_poolMap(nexon.console.BASE.params.bands);
            nexObj.poolCfg.ax.f.segOpts=["bins","bands"];
            nexObj.poolCfg.ax.f.poolMaps = "regions";
            nexObj.poolCfg.ax.chans.segOpts=["bins","regions"];
            % state cfgs
            nexObj.isOnline = 1;
            nexObj.isStatic = 0;
            % modelPath = "/home/user/Code_Repo/n-CORTEx/utils/RTSpec/Models/biLSTM50.pth";
            % try
            %     % obj.rtSpec = initRTSpec(nexon.console.BASE.params, []);
            %     obj.rtSpec = [];
            % catch e
            %     disp(getReport(e));
            %     obj.rtSpec = [];
            % end
            nexObj.pltTimer=timer("ExecutionMode","fixedRate","BusyMode","drop","Period",0.1,"TimerFcn",@(~,~)animate(nexObj, nexon, shank));
            nexObj.isPlay=0;
            % obj = nexPlot_channelGram(nexon, shank, obj);                                
            nexObj = nexFigure_channelGram(nexObj);                                
        end

        function updateScope(nexObj, nexon)            
            % grab next dataframe
            % frameBufferID = sprintf("frameBuffer_chg--%s",obj.dfID);
            nexObj.dataFrame = grabDataFrame(nexon, nexObj.dfID,[]);            
            nexObj.DF.df = grabDataFrame(nexon, nexObj.dfID,[]);
            aniArgs = nexObj.aniCfg.entryParams;
            opArgs = nexObj.opCfg.entryParams;
            opArgs.frameNum = nexObj.frameNum; % custom arg for operation sequence
            try                
                % obj.frameBuffer = grabDataFrame(nexon, frameBufferID,[]); % % TESTING
                nexObj.frameBuffer = retrieveFrameBuffer(nexObj);
                % if df recovery possible but missing necessary entries
                if isempty(nexObj.frameBuffer) || ~isfield(nexObj.frameBuffer,"ax") || ~isfield(nexObj.frameBuffer,"opArgs") || ~isfield(nexObj.frameBuffer,"aniArgs")
                    disp("save buffer could not be recovered");
                    nexObj.frameBuffer=struct;
                    nexObj.frameBuffer.frameIds=nexObj.frameNum;                    
                    nexObj.frameBuffer.opArgs=struct;
                    nexObj.frameBuffer.aniArgs=struct;
                    % OPERATE (online/offline dependent)
                    df_slice = nexObj.DF.df(:,nexObj.frameNum:nexObj.frameNum+nexObj.aniCfg.entryParams.windowLen);
                    % opArgs = obj.opCfg.entryParams;                    
                    opFcn_out = nexObj.opCfg.opFcn(df_slice, opArgs);
                    df_out = opFcn_out.df;
                    nexObj.frameBuffer.ax = opFcn_out.ax;
                    nexObj.frameBuffer.frames = opFcn_out.df;
                else
                    try                        
                        nexObj.frameNum = nexObj.frameBuffer.currentFrame;
                    catch
                        nexObj.frameNum = min(nexObj.frameBuffer.frameIds);
                    end
                    [df_out, ax] = nexDeBufferFrame(nexObj.frameBuffer, nexObj.frameNum);
                end
            catch e % if df recovery fails
                disp(getReport(e));
                nexObj.frameBuffer=struct;
                nexObj.frameBuffer.frameIds=nexObj.frameNum;                                    
                nexObj.frameBuffer.opArgs=struct;
                nexObj.frameBuffer.aniArgs=struct;
                % OPERATE (online/offline dependent)
                df_slice = nexObj.DF.df(:,nexObj.frameNum:nexObj.frameNum+nexObj.aniCfg.entryParams.windowLen);
                % opArgs = obj.opCfg.entryParams;                
                opFcn_out = nexObj.opCfg.opFcn(df_slice, opArgs);
                df_out = opFcn_out.df;
                nexObj.frameBuffer.ax = opFcn_out.ax;
                nexObj.frameBuffer.frames = opFcn_out.df;
            end
            % Recover DF_postOp (for updating subObjs)
            nexObj.DF_postOp.df = nexObj.frameBuffer.frames;
            nexObj.DF_postOp.ax = nexObj.frameBuffer.ax;
            % df_out = obj.frameBuffer.frames(:,:,floor(obj.frameNum/aniArgs.stride)); % approximate, but good for now
            % ax = obj.DF_postOp.ax;
            
            % VISUALIZE
            % shank = obj.Parent;
            visArgs = nexObj.visCfg.entryParams;
            nexObj.visCfg.visFcn(nexon, nexObj, visArgs);
            % obj.visCfg.visFcn(nexon, shank, obj, df_out, ax, visArgs);
            % update children objs
            nex_updateChildren(nexon, nexObj);
        end

        function reportAverage(nexObj, selIdx)
            %% RETRIEVAL
            dfID = sprintf("%s--%s",nexObj.classID,func2str(nexObj.opCfg.opFcn));
            dfTag = sprintf("%s_df",dfID);
            tTag = sprintf("%s_t",dfID);
            dfCol = nexObj.nexon.console.BASE.DTS.(dfTag);
            tCol = nexObj.nexon.console.BASE.DTS.(tTag);            
            %% MASK SELECTION
            if isempty(selIdx)
                S = nex_returnSelectionMask(nexObj.nexon.console.BASE.controlPanel.averagingSelection);
                maskIdx = nex_applySelectionMask(nexObj.nexon.console.BASE.DTS,S);
                dfCol_sel = dfCol(maskIdx);
                tCol_sel = tCol(maskIdx);
            else
                dfCol_sel = dfCol(selIdx);
                tCol_sel = tCol(selIdx);
                maskIdx = selIdx;
            end
            %% ALIGNMENT
            try
                S_slrt = nex_returnSelectionMask(nexObj.nexon.console.SLRT.signals.eventAlignmentSelection);
                alignColTags = split(S_slrt.events,"_");
                tColID = sprintf("%s_aligned_%s_%s_time",alignColTags(1),alignColTags(2),alignColTags(3));
                tCol_slrt = nexObj.nexon.console.BASE.DTS.(tColID)(maskIdx);
                fs_slrt = nexObj.nexon.console.SLRT.signals.UserData.Fs;
                t_preBuff = nexObj.preBufferLen;
                [dfCol_aligned, tCol_aligned] = nexAlign_signals(dfCol_sel, tCol_sel, tCol_slrt, fs_slrt, t_preBuff,3);            
            catch e
                disp(getReport(e));
                dfCol_aligned = dfCol_sel;
                tCol_aligned = tCol_sel;
            end
            %% AXIS POOLING ***
            % segment axes by poolCfg
            % poolMap = extractPoolMap(nexObj);
            try
                [dfCol_pooled_freqs, binIDs_freqs]  = cellfun(@(DF) nexAnalysis_averagePool(DF, nexObj.pMap_freqs, 2), dfCol_aligned, "UniformOutput",false);
                [dfCol_pooled, binIDs_chans] = cellfun(@(DF) nexAnalysis_averagePool(DF, nexObj.pMap_chans, 1), dfCol_pooled_freqs,"UniformOutput",false);
            catch e
                disp(getReport(e));
                dfCol_pooled = dfCol_aligned;
                % ax_pooled_freqs
                % tCol_pooled =
            end
            %% AVERAGE RESULT
            [dfAvg, dfStd] = nex_colAvg(dfCol_pooled, 3);                        
            % dfStd = nex_colStd(dfCol_aligned, 3);
            nexObj.DF_postOp.df = dfAvg;
            nexObj.DF_postOp.ax.t = tCol_aligned{1};
            nexObj.DF_postOp.bins.f = binIDs_freqs;
            nexObj.DF_postOp.bins.chans = binIDs_chans;
            nexObj.DF_postOp.std = dfStd;
            avgCfg_sel = nexObj.nexon.console.BASE.controlPanel.averagingSelection.selections;
            avgCfg_keys = nexObj.nexon.console.BASE.controlPanel.averagingSelection.selKeys;
            avgCfg = nex_structfun2(@(cfgSel, cfgKey) cfgKey(cfgSel), avgCfg_sel, avgCfg_keys);
            nexObj.DF_postOp.avgCfg = avgCfg;
            % swap frameBuffer
            nexObj.frameBuffer.frames = dfAvg;
            %% STORE RESULT AND CFG ***
            nex_storeAverage(nexObj, nexObj.DF_postOp); % selection wise storing
            %% VISUALIZE RESULT            
            nexObj.visualize();
            % update children objs
            nex_updateChildren(nexObj.nexon, nexObj);
        end

        function  storeAverage(nexObj, DF_avg)
            % store average at matching cfg site
            AVG.(phase) 
            avgCfg = controlPanelSelection;
            % create a table if none exists
            if isempty(nexObj.UserData.DTS_avg)
                nexObj.UserData.DTS_avg = table(struct,struct,'VariableNames',{'DF_avg','DF_cfg'});
            end            
        end

        function scaleAnalysis(nexObj)
            % use nexObj computeFcn on all pointed-source dataframes
            % apply analysis method to all trials in the DTS
            analysisArgs = nexObj.compCfg.entryParams;
            analysisArgs.preBuffLen = nexObj.preBufferLen;            
            % special target label
            opFcnName = func2str(nexObj.opCfg.opFcn);
            dfID_target = sprintf("%s--%s",nexObj.classID,opFcnName);
            % upgrade opFcn to DF-sized method
            analysisFcn = str2func(sprintf("%s_roll",opFcnName));
            nexAnalysis_scaleAnalysis(nexObj.nexon, nexObj.classID, analysisFcn, analysisArgs,  nexObj.dfID_source, dfID_target, []);
        end

        function visualize(nexObj)
            visArgs = nexObj.visCfg.entryParams;
            nexObj.visCfg.visFcn(nexObj.nexon, nexObj, visArgs);
        end

        function animate(nexObj, nexon, shank)
            args = nexObj.aniCfg.entryParams;
            nexAnimate_channelGram(nexon, shank, nexObj, args);
        end               
    end
end