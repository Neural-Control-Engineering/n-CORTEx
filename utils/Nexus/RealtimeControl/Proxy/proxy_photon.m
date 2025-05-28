classdef proxy_photon < handle
    properties
        proxon
        nCORTEx
        proxyID = "photon";       
        type=2
        Server
        compCfg
        nexFigures % handles to interactive figures
        stream
        writeBuffer
        readBuffer
        captureBuffer        
        EN_capStream
        EN_rtStream
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_photon(serverIP, nCORTEx)            
            proxObj.Server = actxserver('PrairieLink64.Application');  
            proxObj.Server.Connect()
            proxObj.stream = timer("ExecutionMode","fixedRate","BusyMode","queue","Period",0.1,"TimerFcn",@(~,~)proxObj.readData);                        
            % application handle
            proxObj.nCORTEx = nCORTEx;
            % startup and configuration
            % proxObj.nCORTEx.params
            setupRepo = fullfile(proxObj.nCORTEx.nCORTEx_repo,"Setup","photon");
            proxObj.Server.SendScriptCommands("-spc");
            proxObj.Server.SendScriptCommands(sprintf("-lspf %s", fullfile(setupRepo,"stage_default.xy")));
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