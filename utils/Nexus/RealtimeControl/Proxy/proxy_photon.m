classdef proxy_photon < handle
    properties
        proxyID = "photon";                        
        Server
        compCfg
        nexFigures % handles to interactive figures
        captureBuffer
        stream
        EN_capStream
        EN_rtStream
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_photon(serverIP)            
            proxObj.Server = actxserver('PrairieLink64.Application');   
            proxObj.stream = timer("ExecutionMode","fixedRate","BusyMode","queue","Period",0.1,"TimerFcn",@(~,~)proxObj.readData);                        
        end

        % FETCH DATA
        function readData(proxObj)
        end

        function writeData(proxObj)
        end

        % Z-Stack
        function zStack(proxObj)
        end

        % T-series
        function tSeries(proxObj)
        end

        % Open shuter
        function openShutter(proxObj)
        end

        % close shutter
        function closeShutter(proxObj)
        end

        function sessionLabelChanged(proxObj)
        end

    end

end