classdef proxy_slrt < handle
    % the slrt proxy is itself a proxy as well as a manager of each proxy
    % associated with a neural recording device 
    % it will mediate incoming and outgoing commands/transmissions to and
    % from a simulink realtime model that enables 1) online reading/writing
    % from target devices (neural recording/stimulating platforms, cameras,
    % actuators, peripheral instruments, etc.), 2) online compiling of
    % datastores for in-situ/human-in-the-loop analysis and 3) online
    % visualization of data streams as they are recorded and processed -
    % these capacities are distributed among the slrt proxy and its
    % associated target/device proxies
    properties
        proxon
        proxyID = "slrt"
        type=1
        Partners
        slTarget
        Server % transport layer server that receives and sends transmissions from the main slrt process (happening on realtime computer, typiclly remote)        
        Client % transport layer client 
        compCfg
        nexFigures
        ctrlKey
        Targets; % handles to proxies associated with peripheral  target devices (spikeGl, prairielink, etc.)        
        % isCapturing=0;
        % isStreaming=0;
        DTS
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_slrt(serverIP, serverPort, clientIP, clientPort, slTarget, tgProxies, connectionChangedFcn)            
            proxObj.Server = tcpserver(serverIP, serverPort,"ConnectionChangedFcn",@(src,event)connectionChangedFcn(src, event));
            if ~isempty(clientIP)
                proxObj.Client = tcpclient(clientIP, clientPort, "ConnectionChangedFcn", @(src, event)connectionChangedFcn(src, event));                
            else
                proxObj.Client = [];
            end
            % configureCallback(proxObj.Server,"byte",1,@(src, evnt)proxObj.relayTransmission(params,server,modalityServer.modSrv));    
            % configureCallback(proxObj.Server,"byte",1,@(src, evnt)proxObj.relayTransmission(proxObj));    
            configureCallback(proxObj.Server,"byte",25,@(~,~)proxObj.relayTransmission());
            
            proxObj.Targets = tgProxies;            
            % proxObj.ctrlKey = ctrlKey();
            proxObj.slTarget = slTarget;
        end

        function relayTransmission(proxObj)            
            %% read command code (simple for now)
            % cmdCode = read(proxObj.Server,proxObj.Server.NumBytesAvailable,"uint8");             
            cmdCode = read(proxObj.Server,25,"uint8");             
            cmdRx = uint8(zeros(25,1));
            cmdBuffer = find(cmdCode>=1);
            for i = 1:length(cmdBuffer)
                idx_cmd = cmdBuffer(i);
                switch idx_cmd
                    case 7 % z-stack
                        proxObj.proxon.index_type2.photon_2.zStack();                        
                end
            end
            %% command lookup
            % command = proxObj.ctrlKey.getCmd(cmdCode);                                 
            % execute designated command (using corresponding target (e.g.
            % start datastream should initiate a subroutine that fetches
            % data from all targets))
            %% execute command
            % proxObj.(methodHandle);

        end

        function addPartner(proxObj, partnerProxObj)
            % share primary peripherals
            partnerProxObj.Targets = proxObj.Targets;
            partnerProxObj.DTS = proxObj.DTS;
        end

        function addTarget(proxObj, targetProxy)
        end

        function startDataStream(proxObj)
        end

        function startCapture(proxObj) % initiate capture protocol that stores a running datastream to associated DTS
            % retrieve target data (whatever's left in the transmission)
            targetCode = read(proxObj.Server,proxObj.Server.NumBytesAvailable,"uint8");
            targetID = targetKey.getTargetID(targetCode);
            % initialize target capStream

        end

        function endCapture(proxObj) % end capture protocol
            targetCode = read(proxObj.Server,proxObj.Server.NumBytesAvailable,"uint8");
            targetID = targetKey.getTargetID(targetCode);
            % end target capStream
        end

        function writeToDTS(proxObj) % recieve a datagram and assign to associated DTS
        end

        function sessionLabelChanged(proxObj)
        end

        function readAllTargets(proxObj)
        end

        function writeAllTargets(proxObj)
        end

        function endOfTrial(proxObj)
        end


    end

end