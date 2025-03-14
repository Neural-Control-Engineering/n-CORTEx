classdef nexObj_spectroGram < handle
    properties
        classID
        nexon        
        Parent % hold parent nexObjs (e.g. channelgram)
        DF
        DF_postOp
        dataFrame % This will hold any type of data, such as a struct     
        entryPanel
        dfID % DTS df identifier (trial-wise)
        f % frequency axis
        t % time axis
        opCfg
        visCfg
        isOnline
        isStatic
        freqResponse
        spgFigure % figure handle
        UserData
        bPool
    end
    
    methods
        % Constructor
        function obj = nexObj_spectroGram(nexon, channelGram, dataFrame, dfID, f, t, opFcn, visFcn)
            obj.classID = "spg";
            obj.nexon = nexon;
            obj.Parent = channelGram;
            obj.DF = obj.Parent.DF_postOp;
            obj.DF_postOp.df=[]; obj.DF_postOp.ax.t=[]; obj.DF_postOp.ax.f=[];
            obj.dataFrame=dataFrame;            
            obj.dfID = dfID;
            obj.f = f;
            obj.t = t;            
            % operation function
            if ~isempty(opFcn)
                obj.opCfg.opFcn = opFcn;
            else
                obj.opCfg = struct;
            end
            try
                obj.opCfg.entryParams = extractMethodCfg(rmExtension(func2str(opFcn)));
            catch e
                disp(getReport(e));
                obj.opCfg.entryParams = struct;
                obj.opCfg.opFcn=[];
            end
            % visualization function
            obj.visCfg.visFcn = visFcn;
            try
                obj.visCfg.entryParams = extractMethodCfg(rmExtension(func2str(visFcn)));
            catch e
                disp(getReport(e));
                obj.visCfg.entryParams = struct;
            end
            obj.UserData = struct;
            obj.UserData.chanSel = 1;
            % state Cfgs
            obj.isOnline=1;
            obj.isStatic=1;
            % DRAW SPECTROGRAM
            nexPlot_spectroGram(nexon, obj);            
            % dfToPool = dataFrame(obj.UserData.chanSel,:,:);
            % [poolDf, b] = poolBands(nexon.console.BASE.params.bands, obj.f, dfToPool);            
            % obj.bPool = nexObj_bandPool(nexon, obj, b, t, [], poolDf, []);
        end

        function updateScope(obj, nexon)
            nexUpdate_spectroGram(nexon, obj);  
        end          
    end
end