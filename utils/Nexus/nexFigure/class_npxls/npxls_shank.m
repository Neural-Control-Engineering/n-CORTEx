classdef npxls_shank < handle
    properties
        regMap % This will hold any type of data, such as a struct        
        nexon
        classID="npxShnk"
        Parents
        Partners
        Children
        Origins
        DF
        dfID_source="lfp"
        DF_postOp
        dfID_target
        scope        
        config
        pMap
        UserData
    end
    
    methods
        % Constructor
        function nexObj = npxls_shank(nexon)
            nexObj.nexon=nexon;
            nexObj.UserData = struct(); % Initialize as an empty struct
            nexObj.scope = struct();
            % configure Shank Mapping
            params = nexon.console.BASE.params;            
            regMapDir = fullfile(nexon.console.BASE.router.UserData.subjectDir,"npxls/trajectory/imec0","map_channel-region.mat");            
            regMapDir_cloud = fullfile(nexon.console.BASE.router.UserData.subjectDir_cloud,"npxls/trajectory/imec0","map_channel-region.mat");            
            try
                load(regMapDir);
            catch
                load(regMapDir_cloud);
            end
            nexObj.regMap = regMap;    
            % pool config structures
            nexObj.pMap.pMap_freqs = poolMap_freqs(nexObj.nexon.console.BASE.params.bands,[]);
            nexObj.pMap.pMap_chans = poolMap_chans(nexObj.regMap,[]);
            % nexObj.pMap.pMap_time = [];
            % start user with one timeCourse
            % % dataFrame = grabDataFrame(nexon,"lfp",[]);
            % % df_t = grabDataFrame(nexon,"t_lfp",[]);
            %% rename lfp columns into convention
            try
                nexObj.nexon.console.BASE.DTS.Properties.VariableNames{'lfp'}='lfp_df';
                nexObj.nexon.console.BASE.DTS.Properties.VariableNames{'t_lfp'}='lfp_t';
            catch e
                disp(getReport(e))
            end
            % 
            % if isempty(dataFrame)
            %     dataFrame = grabDataFrame(nexon,"lfp_df",[]);
            % end
            % nexObj.DF = lfp2DF(dataFrame, df_t);            
            nexObj.DF = dtsIO_readDF(nexObj.nexon, "lfp",[]);
            nexObj.DF_postOp = nexObj.DF;            
            % nexObj.scope.timeCourse1 = nexObj_npxlsTimeCourse(nexon, nexObj, dataFrame, "lfp");
            nexObj.scope.timeCourse1 = nexObj_npxlsTimeCourse(nexon, nexObj, nexObj.DF, "lfp");
            % nexObj.scope.timeCourse.DF = nexObj.DF;
            %% PIXELGRAM
            nexObj_pixelGram(nexObj.scope.timeCourse1, nexObj.nexon);
            %% add STFT (PMTM method spectrogram)
            try
                df_lfp = grabDataFrame(nexon,"lfp",[]);
                % parfeval(@() nexnexObj_channelGram(nexon, nexObj, rtSpectrogram,"lfp","mag"),0);
                % nexObj.scope.channelgram1 = nexnexObj_channelGram(nexon, nexObj, rtSpectrogram, "lfp", "mag");
                opFcn = str2func("rtPMTM_magnitude");
                visFcn = str2func("nexVisualization_channelGram");
                aniFcn = str2func("nexAnimate_channelGram");
                nexObj.scope.channelGram1 = nexObj_channelGram(nexon, nexObj, df_lfp, "lfp", opFcn, visFcn, aniFcn);
            catch e
                disp(getReport(e));
            end
            try
                % spg1 = grabSpectrogram(nexon, "pmtm",[]);
                spg1.dataFrame=[];
                spg1.dfID = [];
                spg1.f = [];
                spg1.t = [];
                spg1.opFcn = [];
                spg1.visFcn = str2func("nexVisualization_spectroGram");
                spg1.isOnline = 1;
                nexObj.scope.channelGram1.Children.spectroGram1 = nexnexObj_spectroGram(nexon, nexObj.scope.channelGram1, spg1.dataFrame, spg1.dfID, spg1.f, spg1.t, spg1.opFcn, spg1.visFcn);
                spectroGram1 = nexObj.scope.channelGram1.Children.spectroGram1;
            catch e
                disp(getReport(e));
            end
            try
                nexObj.scope.channelGram1.Children.spectroGram1.Children.spectroGraph1 = nexnexObj_spectroGraph(nexon, spectroGram1, [], [], [], []);
            catch e
                disp(getReport(e));
            end
            try
                opFcn = str2func("spectralParameterization");
                % nexObj.scope.channelGram1.Children.spectroScope1 = nexnexObj_spectroScope(nexon, nexObj.scope.channelGram1, opFcn);
            catch  e
                disp(getReport(e))
            end
            % Embedding figure
            opFcn = str2func("embedUMAP");
            dfID = "rtPMTM_magnitude_temporal";
            % nexObj.Children.embedding1 = nexnexObj_embedding(nexon, nexObj, opFcn, dfID);
            
            % add CWT spectrogram (wavelet transform)
            % try
            %     spg2 = grabSpectrogram(nexon, "cwt",[]);
            %     nexObj.scope.spectrogram2 = nexnexObj_spectroGram(nexon, nexObj, spg2.dataFrame, spg2.dfID, spg2.f, spg2.t, "mag");
            % catch e
            %     disp(e);
            % end
            % nexObj.config = struct();
            % draw config Panel
            % nexObj.config = drawShankCfgPanel(nexon, nexObj);                          
        end

        function updateRegMap(nexObj)
            disp("New subject selected, updating region mapping")
            params = nexObj.nexon.console.BASE.params;            
            regMapDir = fullfile(nexObj.nexon.console.BASE.router.UserData.subjectDir,"npxls/trajectory/imec0","map_channel-region.mat");            
            regMapDir_cloud = fullfile(nexObj.nexon.console.BASE.router.UserData.subjectDir_cloud,"npxls/trajectory/imec0","map_channel-region.mat")            
            try
                load(regMapDir);
            catch
                load(regMapDir_cloud);
            end
            nexObj.regMap = regMap;    
        end

        function reportAverage(nexObj, selIdx)            
            %% RETRIEVAL
            % dfID = sprintf("%s--%s",nexObj.classID,func2str(nexObj.opCfg.opFcn));
            dfID = nexObj.scope.dfID_source;
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
                % tColID = sprintf("%s_aligned_%s_%s_time",alignColTags(1),alignColTags(2),alignColTags(3));
                tColID = sprintf("%s_aligned_%s_time",alignColTags(1),alignColTags(2));
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
                freqs = nexObj.DF_postOp.ax.f;
                chans = nexObj.DF_postOp.ax.chans;
                [dfCol_pooled_freqs, binIDs_freqs]  = cellfun(@(DF) nexAnalysis_averagePool(DF, nexObj.pMap_freqs, 2, freqs), dfCol_aligned, "UniformOutput",false);
                [dfCol_pooled, binIDs_chans] = cellfun(@(DF) nexAnalysis_averagePool(DF, nexObj.pMap_chans, 1, chans), dfCol_pooled_freqs,"UniformOutput",false);
            catch e
                disp(getReport(e));
                dfCol_pooled = dfCol_aligned;
                binIDs_freqs = nexObj.DF_postOp.ax.f;
                binIDs_chans = nexObj.DF_postOp.ax.chans;
                % ax_pooled_freqs
                % tCol_pooled =
            end
            %% AVERAGE RESULT
            [dfAvg, dfSem] = nex_colAvg(dfCol_pooled, 3);                        
            % dfStd = nex_colStd(dfCol_aligned, 3);
            nexObj.DF_postOp.df = dfAvg;
            nexObj.DF_postOp.ax.t = tCol_aligned{1};
            nexObj.DF_postOp.bins.f = binIDs_freqs;
            nexObj.DF_postOp.bins.chans = binIDs_chans;
            nexObj.DF_postOp.sem = dfSem;
            avgCfg_sel = nexObj.nexon.console.BASE.controlPanel.averagingSelection.selections;
            avgCfg_keys = nexObj.nexon.console.BASE.controlPanel.averagingSelection.selKeys;
            avgCfg = nex_structfun2(@(cfgSel, cfgKey) cfgKey(cfgSel), avgCfg_sel, avgCfg_keys);
            % apply additional averaging configurations
            avgCfg.poolType_freqs=nexObj.pMap.pMap_freqs.binType;
            avgCfg.poolType_chans=nexObj.pMap.pMap_chans.binType;
            nexObj.DF_postOp.avgCfg = avgCfg;
            % swap frameBuffer
            nexObj.frameBuffer.frames = dfAvg;
            %% STORE RESULT AND CFG ***
            nex_storeAverage(nexObj, nexObj.DF_postOp); % selection wise storing
            %% VISUALIZE RESULT            
            try
                nexObj.visualize();
            catch e
                disp(getReport(e));
            end
            % update children objs
            nex_updateChildren(nexObj.nexon, nexObj);
        end
        % 
        function updateScope(nexObj)
            % recover dataframe and update Children            
            nex_updateChildren(nexObj.nexon, nexObj);
        end
    end
end

% nexon.console.NPXLS.shanks.shank1.Children.embedding=nexnexObj_embedding(nexon, nexObj, opFcn, dfID);