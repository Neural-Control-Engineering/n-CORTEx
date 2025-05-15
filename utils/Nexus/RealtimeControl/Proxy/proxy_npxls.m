classdef proxy_npxls < handle
    properties
        proxon
        proxyID = "npxls";  
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
        function proxObj = proxy_npxls(serverIP)
            startSGL();
            % SpikeGL('start');

            proxObj.Server = SpikeGL(char(serverIP)); % spikeGL            
            proxObj.writeBuffer = timer("ExecutionMode","fixedRate","BusyMode","queue","Period",0.1,"TimerFcn",@(~,~)proxObj.readData);                        
        end

        % Fetch data
        function df = readData(proxObj)
            df = FetchLatest(proxObj.Server, 2, 0, windowLen);          
            % computation during fetching
            % visualize during fetching
            % return template data if server does not exist
        end

        function updateSessionLabel(proxObj, SL)
            % remove gate suffix
            ungatedSL = split(SL,'_');
            ungatedSL = ungatedSL(1:end-1);
            ungatedSL = string(join(ungatedSL,'_'));
            if ~IsRunning(proxObj.Server); SetRunName(proxObj.Server,char(ungatedSL)); end  
        end
    end

end