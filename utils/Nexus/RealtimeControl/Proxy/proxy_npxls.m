classdef proxy_npxls < handle
    properties
        proxyID = "npxls";                        
        Server      
        compCfg
        nexFigures % handles to interactive figures
        stream
        captureBuffer
        EN_capStream
        EN_rtStream
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_npxls(serverIP)
            proxObj.Server = SpikeGL(chat(serverIP)); % spikeGL            
            proxObj.stream = timer("ExecutionMode","fixedRate","BusyMode","queue","Period",0.1,"TimerFcn",@(~,~)proxObj.readData);                        
        end

        % Fetch data
        function df = readData(proxObj)
            df = FetchLatest(proxObj.Server, 2, 0, windowLen);          
            % computation during fetching
            % visualize during fetching
            % return template data if server does not exist
        end

        function sessionLabelChanged(proxObj)
        end
    end

end