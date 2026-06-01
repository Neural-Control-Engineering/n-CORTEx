classdef nexObj_npxlsTimeCourse < handle
    properties
        classID = "npxTC"
        nexon
        Parent
        Origin
        Children        
        Partners
        dataFrame % This will hold any type of data, such as a struct  
        dfID
        dfID_source
        dfID_target
        DF
        DF_postOp
        pMap
        UserData
        entryPanel
        tcFigure
    end
    
    methods
        % Constructor
        function nexObj = nexObj_npxlsTimeCourse(nexon, shank, DF, dfID)
            nexObj.nexon = nexon;
            nexObj.nexon.console.BASE.nexObjs.npxlsTc_1 = nexObj;            
            nexObj.Parent = shank;            
            nexObj.Children = struct;
            nexObj.dataFrame=DF.df;       
            % nexObj.DF.df = dataFrame;
            nexObj.DF = DF;
            nexObj.dfID = dfID;
            nexObj.dfID_source=dfID;
            nexObj.UserData=struct();
            nexObj.UserData.Fs = 500;
            nexObj.UserData.preBufferLen=3.5; % initial lab standard
            % pool mapping
            nexObj.pMap.pMap_freqs = poolMap_freqs(nexObj.nexon.console.BASE.params.bands,[]);
            nexObj.pMap.pMap_chans = poolMap_chans(nexObj.Parent.regMap,[]);
            % Figure drawing
            nexObj = nexPlot_npxls_timeCourse(nexon, shank, nexObj);
            nexObj.Origin = nexObj;
        end

        function updateScope(nexObj, nexon)
            nexObj.DF = dtsIO_readDF(nexObj.nexon, nexObj.dfID_source, []);
            % patch
            if ~isfield(nexObj.DF,"ax")
                nexObj.DF.ax.t=[1:size(nexObj.DF.df,2)]./nexObj.UserData.Fs - nexObj.UserData.preBufferLen;
                nexObj.DF.ax.chans=[1:size(nexObj.DF.df,1)];
            end
            % patch
            nexObj.DF_postOp = nexObj.DF;
            %% VISUALIZE RESULT
            nexObj.visualize();
            %% UPDATE CHILDREN/PARTNERS
            nex_updateChildren(nexObj.nexon, nexObj);
            nex_updatePartners(nexObj);
        end

        function reportAverage(nexObj, selIdx)
            %% RETRIEVAL
            % dfID = sprintf("%s--%s",obj.classID,func2str(obj.opCfg.opFcn));
            dfID = nexObj.dfID_source;
            dfTag = sprintf("%s_df",dfID);
            dfTag_t = sprintf("%s_t",dfID);
            dfTag_chans = sprintf("%s_chans",dfID);
            % tTag = sprintf("%s_t",dfID);
            dfCol = nexObj.nexon.console.BASE.DTS.(dfTag);
            % time axis
            try
                tCol = nexObj.nexon.console.BASE.DTS.(dfTag_t);
            catch
                tCol = cellfun(@(x) [1:size(x,2)]/nexObj.UserData.Fs-nexObj.UserData.preBufferLen,dfCol,"UniformOutput",false);
            end               
            % channel axis
            try
                chanCol = nexObj.nexon.console.BASE.DTS.(dfTag_chans);
            catch                
                chanCol = cellfun(@(x) [1:size(x,1)],dfCol,"UniformOutput",false);                               
            end                      
            
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
                t_preBuff = nexObj.UserData.preBufferLen;
                [dfCol_aligned, tCol_aligned] = nexAlign_signals(dfCol_sel, tCol_sel, tCol_slrt, fs_slrt, t_preBuff, 2);            
            catch e
                disp(getReport(e))
                dfCol_aligned = dfCol_sel;
                tCol_aligned = tCol_sel;
            end
            %% AXIS POOLING ***         
            try                
                chans = nexObj.DF_postOp.ax.chans;                
                [dfCol_pooled, binIDs_chans] = cellfun(@(DF) nexAnalysis_averagePool(DF, nexObj.pMap.pMap_chans, 1, chans), dfCol_aligned,"UniformOutput",false);
                chans = 1:size(binIDs_chans{1,1});
            catch e
                disp(getReport(e));
                chans = chanCol{1,1};
                dfCol_pooled = dfCol_aligned;                
                % binIDs_chans = nexObj.DF_postOp.ax.chans;                
                binIDs_chans = chans;                
            end            
            %% AVERAGE RESULT
            % [dfAvg, dfStd] = nex_colAvg(dfCol_aligned, 2);                        
            [dfAvg, dfSem] = nex_colAvg(dfCol_pooled, 2);                        
            t = cellfun(@(t) nex_trimDf(t,2,[1:size(dfAvg,2)]), tCol_aligned,"UniformOutput",false);
            %% EXTRACT AVGCFG
            avgCfg_sel = nexObj.nexon.console.BASE.controlPanel.averagingSelection.selections;
            avgCfg_keys = nexObj.nexon.console.BASE.controlPanel.averagingSelection.selKeys;
            avgCfg = nex_structfun2(@(cfgSel, cfgKey) cfgKey(cfgSel), avgCfg_sel, avgCfg_keys);
            % apply additional averaging configurations            
            avgCfg.poolType_chans=nexObj.pMap.pMap_chans.binType;                        
            nexObj.DF_postOp.df = dfAvg;
            nexObj.DF_postOp.sem = dfSem;
            nexObj.DF_postOp.ax.t = t{1};   
            nexObj.DF_postOp.ax.chans = chans;
            nexObj.DF_postOp.bins.chans = binIDs_chans;
            nexObj.DF_postOp.avgCfg = avgCfg;
            %% STORE RESULT AND CFG ***
            nex_storeAverage(nexObj, nexObj.DF_postOp); % selection wise storing
            % nexObj.DF_postOp = nexObj.DF;
            %% VISUALIZE RESULT
            nexObj.visualize();
            %% UPDATE CHILDREN/PARTNERS
            nex_updateChildren(nexObj.nexon, nexObj);
            nex_updatePartners(nexObj);
        end

        function partialFit(nexObj, selIdx)
            % train a model on selected trials (using partial fit)
            %% RETRIEVAL
            dfID = nexObj.dfID_source;
            dfTag = sprintf("%s_df",dfID);
            dfTag_t = sprintf("%s_t",dfID);
            dfTag_chans = sprintf("%s_chans",dfID);
            % tTag = sprintf("%s_t",dfID);
            dfCol = nexObj.nexon.console.BASE.DTS.(dfTag);
            % time axis
            try
                tCol = nexObj.nexon.console.BASE.DTS.(dfTag_t);
            catch
                tCol = cellfun(@(x) [1:size(x,2)]/nexObj.UserData.Fs-nexObj.UserData.preBufferLen,dfCol,"UniformOutput",false);
            end               
            % channel axis
            try
                chanCol = nexObj.nexon.console.BASE.DTS.(dfTag_chans);
            catch                
                chanCol = cellfun(@(x) [1:size(x,1)],dfCol,"UniformOutput",false);                               
            end                      
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
                t_preBuff = nexObj.UserData.preBufferLen;
                [dfCol_aligned, tCol_aligned] = nexAlign_signals(dfCol_sel, tCol_sel, tCol_slrt, fs_slrt, t_preBuff, 2);            
            catch e
                disp(getReport(e))
                dfCol_aligned = dfCol_sel;
                tCol_aligned = tCol_sel;
            end            
            %% AXIS POOLING
            try                
                % chans = nexObj.DF_postOp.ax.chans;                
                % [dfCol_pooled, binIDs_chans] = cellfun(@(DF) nexAnalysis_averagePool(DF, nexObj.pMap.pMap_chans, 1, chans), dfCol_aligned,"UniformOutput",false);
                % chans = 1:size(binIDs_chans{1,1});
                % disp(getReport(e));
                chans = chanCol{1,1};
                dfCol_pooled = dfCol_aligned;                
                % binIDs_chans = nexObj.DF_postOp.ax.chans;                
                binIDs_chans = chans;                
            catch e
                disp(getReport(e));
                chans = chanCol{1,1};
                dfCol_pooled = dfCol_aligned;                
                % binIDs_chans = nexObj.DF_postOp.ax.chans;                
                binIDs_chans = chans;                
            end                        
            %% FIT RESULT  (iterate)          
            % import model (cebra default for now)
            mlObj = mlObj_cebra();
            for i = 1:size(dfCol_pooled,1)
                X = dfCol_pooled{i}'; % transpose for time ax first
                Y = [1:size(X,1)]; % leave as time index for time only
                mlObj.partialFit(X, Y);
            end                               
            try
                disp("embedding complete");
                if ~isfield(nexObj.Partners,"emb1")
                    nexObj.Partners.emb1 = nexObj_embedding_single(nexObj, mlObj);
                else
                    nexObj.Partners.emb1.mlObj=mlObj;
                end
            catch
                assignin("base","mlObj",mlObj);
                disp("no embedding obj registered, leaving output in the base workspace");
            end
        end

        function writeDataset(nexObj)
            % prepare X
            % prepare Y
        end

        function fit(nexObj)
        end

        function visualize(nexObj)
            regMap = nexObj.Parent.regMap;
            updateTimeCourse(nexObj.Parent, nexObj, regMap);
        end
        
        % Example method to set UserData
        function setUserData(obj, data)
            obj.UserData = data;
        end
        
        % Example method to retrieve UserData
        function data = getUserData(obj)
            data = obj.UserData;
        end
    end
end