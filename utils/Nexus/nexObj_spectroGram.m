classdef nexObj_spectroGram < handle
    properties
        dataFrame % This will hold any type of data, such as a struct     
        entryPanel
        dfID % DTS df identifier (trial-wise)
        f % frequency axis
        t % time axis
        freqResponse
        spgFigure % figure handle
        UserData
        bPool
    end
    
    methods
        % Constructor
        function obj = nexObj_spectroGram(nexon, shank, dataFrame, dfID, f, t, freqResponse)
            obj.dataFrame=dataFrame;            
            obj.dfID = dfID;
            obj.f = f;
            obj.t = t;
            obj.freqResponse = freqResponse;
            obj.UserData = struct;
            obj.UserData.chanSel = 1;
            obj.spgFigure = nexPlot_npxls_spectrogram(nexon, shank, obj);
            dfToPool = dataFrame(obj.UserData.chanSel,:,:);
            [poolDf, b] = poolBands(nexon.console.BASE.params.bands, obj.f, dfToPool);            
            obj.bPool = nexObj_bandPool(nexon, obj, b, t, [], poolDf, []);
        end

        function updateScope(obj, nexon, shank)
            psdModifier = split(obj.dfID,"_");
            psdModifier = psdModifier(2);
            % align frequeny and time vectors
            obj.f = grabDataFrame(nexon,sprintf("f_%s",psdModifier),[]);
            obj.t = grabDataFrame(nexon,sprintf("t_%s",psdModifier),[]);
            switch obj.freqResponse
                case "mag"
                    obj.spgFigure.Ax.Children.CData =10*log10(abs(squeeze(obj.dataFrame(obj.UserData.chanSel,:,:))));
                    clims = [-99,-83.6];
                case "phase"
                    obj.spgFigure.Ax.Children.CData = angle(squeeze(obj.dataFrame(obj.UserData.chanSel,:,:)));
                    clims = [0,1];
            end
            obj.spgFigure.Ax.Children.YData=obj.f;
            obj.spgFigure.Ax.Children.XData=obj.t;   
            switch psdModifier
                case "cwt"
                    obj.spgFigure.Ax.CLim = clims;
                case "pmtm"
                    obj.spgFigure.Ax.CLim = clims;
            end           
            % update associated band pool dataFrame
            obj.bPool.updateBandPool(nexon, obj);            
            drawnow;
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