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
        classID = "slrt"
        Partners
        slTarget
        Server % transport layer server that receives and sends transmissions from the main slrt process (happening on realtime computer, typiclly remote)        
        Client % transport layer client 
        cmdLUT
        Targets; % handles to proxies associated with peripheral  target devices (spikeGl, prairielink, etc.)        
        isCapturing=0;
        isStreaming=0;
        DTS
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_slrt(ipAddress, portAddress, cmdLUT, slTarget, tgProxies, connectionChangedFcn)
            proxObj.Server = tcpserver(ipAddress, portAddress,"ConnectionChangedFcn",@(src,event)connectionChangedFcn());
            configureCallback(proxObj.Server,"byte",25,@(src, evnt)proxObj.relayTransmission(params,server,modalityServer.modSrv));    
            proxObj.Client = [];
            proxObj.Targets = tgProxies;            
            proxObj.cmdLUT = cmdLUT;
            proxObj.slTarget = slTarget;
        end

        function relayTransmission(proxObj)            
            %% read command code
            cmdCode = read(proxObj.Server,proxObj.Server.NumBytesAvailable,"uint8");             
            %% command lookup
            command = proxObj.cmdLUT(cmdCode);            
            commandParts = split(command,"_");
            methodID = commandParts(1);
            if size(commandParts,1)>1 % check for target modifier
                targetID = commandParts(2);
            else
                methodHandle = sprintf("proxy_slrt");
                methodHandle = str2func(methodHandle);
            end            
            % execute designated command (using corresponding target (e.g.
            % start datastream should initiate a subroutine that fetches
            % data from all targets))
            %% execute command
            proxObj.(methodHandle);

        end

        function addPartner(proxObj, partnerProxObj)
        end

        function addTarget(proxObj, targetProxy)
        end

        function startDataStream(proxObj)
        end

        function startCapture(proxObj) % initiate capture protocol that stores a running datastream to associated DTS
            proxObj.isCapturing = 1;
            % if partnered with nexus proxy
        end

        function endCapture(proxObj) % end capture protocol
            proxObj.isCapturing = 0;
            % store capture in a DTS (if no DTS on file, create one)
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