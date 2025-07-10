classdef proxy_npxls < handle
    properties
        proxon
        nCORTEx
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
        controlPanel
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_npxls(serverIP, nCORTEx)
            startSGL();
            % SpikeGL('start');
            % application handle
            proxObj.nCORTEx = nCORTEx;
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

        function captureDataStream_npxls(proxObj, pyd, sze)
            % buffer lfp data (with time-stamp)
            % for pyd-designated seconds
            duration_capture = pyd(1);
            t_start_slrt = pyd(2);
            subModSel = pyd(3); % ap or lfp or both
            for i = 1:duration_capture
                if i ==1 % keep 3.5 seconds prior
                else
                end
            end
            % write back
            DF.df=captureData;
            DF.ax=[];
            DF.label=[];
            proxObj.proxon.proxObjs.nexus_1.writeCapture(DF);
            % RelayToParentProxies(proxObj,"writeCapture",DF,[]);
        end

        function startCapture_ap(proxObj, pyd, sze)

        end

        function openControlPanel(proxObj, pyd, sze)
            proxObj.controlPanel = nexObj_controlPanel_npxls([],proxObj.nCORTEx);
        end
    end

end