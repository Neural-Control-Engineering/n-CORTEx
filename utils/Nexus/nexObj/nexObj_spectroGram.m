classdef nexObj_spectroGram < handle
    properties
        classID="spg"
        preBuffLen
        nexon
        Origin
        Parent % hold parent nexObjs (e.g. channelgram)
        Children
        DF
        DF_postOp
        dataFrame % This will hold any type of data, such as a struct     
        entryPanel
        dfID % DTS df identifier (trial-wise)
        dfID_source
        dfID_target
        f % frequency axis
        t % time axis
        opCfg
        visCfg
        isOnline
        isStatic
        freqResponse
        spgFigure % figure handle
        Figure
        UserData
        bPool
    end
    
    methods
        % Constructor
        function nexObj = nexObj_spectroGram(nexon, channelGram, dataFrame, dfID, f, t, opFcn, visFcn)            
            nexObj.nexon = nexon;
            nexObj.preBuffLen = channelGram.preBufferLen;
            nexObj.Origin = channelGram;
            nexObj.Parent = channelGram;
            nexObj.DF = nexObj.Parent.DF_postOp;
            nexObj.DF_postOp.df=[]; nexObj.DF_postOp.ax.t=[]; nexObj.DF_postOp.ax.f=[];
            nexObj.dataFrame=dataFrame;            
            nexObj.dfID = dfID;
            nexObj.f = f;
            nexObj.t = t;            
            % operation function
            if ~isempty(opFcn)
                nexObj.opCfg.opFcn = opFcn;
            else
                nexObj.opCfg = struct;
            end
            try
                nexObj.opCfg.entryParams = extractMethodCfg(rmExtension(func2str(opFcn)));
            catch e
                disp(getReport(e));
                nexObj.opCfg.entryParams = struct;
                nexObj.opCfg.opFcn=[];
                nexObj.DF_postOp=nexObj.DF;
            end
            % visualization function
            nexObj.visCfg.visFcn = visFcn;
            try
                nexObj.visCfg.entryParams = extractMethodCfg(rmExtension(func2str(visFcn)));
            catch e
                disp(getReport(e));
                nexObj.visCfg.entryParams = struct;
            end
            nexObj.UserData = struct;
            nexObj.UserData.chanSel = 1;
            % state Cfgs
            nexObj.isOnline=1;
            nexObj.isStatic=1;
            % DRAW SPECTROGRAM
            nexPlot_spectroGram(nexon, nexObj);
            % dfToPool = dataFrame(obj.UserData.chanSel,:,:);
            % [poolDf, b] = poolBands(nexon.console.BASE.params.bands, obj.f, dfToPool);            
            % obj.bPool = nexObj_bandPool(nexon, obj, b, t, [], poolDf, []);
        end

        function updateScope(nexObj, nexon)
            nexUpdate_spectroGram(nexon, nexObj);  
            nex_updateChildren(nexon, nexObj);
        end        

        function addChild(nexObj)
            nexObj.Children.spgph1 = nexObj_spectroGraph(nexObj.nexon, nexObj, [], [], []);
        end

    end
end