classdef nexObj_npxlsTimeCourse < handle
    properties
        classID = "tc_npxls"
        nexon
        Parent
        Children
        dataFrame % This will hold any type of data, such as a struct  
        dfID
        DF
        UserData
        entryPanel
        tcFigure
    end
    
    methods
        % Constructor
        function obj = nexObj_npxlsTimeCourse(nexon, shank, dataFrame, dfID)
            obj.nexon = nexon;
            obj.nexon.console.BASE.nexObjs.npxlsTc_1 = obj;
            obj.Parent = shank;
            obj.Children = struct;
            obj.dataFrame=dataFrame;       
            obj.DF.df = dataFrame;
            obj.dfID = dfID;
            obj.UserData=struct();
            obj.UserData.Fs = 500;
            obj.UserData.preBufferLen=3.5; % initial lab standard
            obj = nexPlot_npxls_timeCourse(nexon, shank, obj);
        end

        function updateScope(obj,  nexon)            
            regMap = obj.Parent.regMap;
            updateTimeCourse(obj.Parent, obj, regMap);
        end

        function reportAverage(obj, selIdx)
            %% RETRIEVAL
            % dfID = sprintf("%s--%s",obj.classID,func2str(obj.opCfg.opFcn));
            dfID = obj.dfID;
            dfTag = sprintf("%s",dfID);
            % tTag = sprintf("%s_t",dfID);
            dfCol = obj.nexon.console.BASE.DTS.(dfTag);
            % tCol = obj.nexon.console.BASE.DTS.(tTag);
            tCol = cellfun(@(x) [1:size(x,2)]/obj.UserData.Fs-obj.UserData.preBufferLen,dfCol,"UniformOutput",false);
            %% MASK SELECTION
            if isempty(selIdx)
                S = nex_returnSelectionMask(obj.nexon.console.BASE.controlPanel.averagingSelection);
                maskIdx = nex_applySelectionMask(obj.nexon.console.BASE.DTS,S);
                dfCol_sel = dfCol(maskIdx);
                tCol_sel = tCol(maskIdx);
            else
                dfCol_sel = dfCol(selIdx);
                tCol_sel = tCol(selIdx);
                maskIdx = selIdx;
            end
            %% ALIGNMENT
            try
                S_slrt = nex_returnSelectionMask(obj.nexon.console.SLRT.signals.eventAlignmentSelection);
                alignColTags = split(S_slrt.events,"_");
                tColID = sprintf("%s_aligned_%s_%s_time",alignColTags(1),alignColTags(2),alignColTags(3));
                tCol_slrt = obj.nexon.console.BASE.DTS.(tColID)(maskIdx);
                fs_slrt = obj.nexon.console.SLRT.signals.UserData.Fs;
                t_preBuff = obj.UserData.preBufferLen;
                [dfCol_aligned, tCol_aligned] = nexAlign_signals(dfCol_sel, tCol_sel, tCol_slrt, fs_slrt, t_preBuff, 2);            
            catch e
                disp(getReport(e))
                dfCol_aligned = dfCol_sel;
                tCol_aligned = tCol_sel;
            end
            %% AVERAGE RESULT
            [dfAvg, dfStd] = nex_colAvg(dfCol_aligned, 2);                        
            t = cellfun(@(t) nex_trimDf(t,2,[1:size(dfAvg,2)]), tCol_aligned,"UniformOutput",false);
            %% VISUALIZE RESULT
            obj.DF.df = dfAvg;
            obj.DF.ax.t = t{1};            
            obj.visualize();
        end

        function visualize(obj)
            obj.updateScope(obj.nexon);
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