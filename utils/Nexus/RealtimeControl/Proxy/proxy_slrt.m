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
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_slrt(ipAddress, portAddress, cmdLUT, slTarget, tgProxies, connectionChangedFcn)
            proxObj.Server = tcpserver(ipAddress, portAddress,"ConnectionChangedFcn",@(src,event)connectionChangedFcn());
            proxObj.Client = [];
            proxObj.Targets = tgProxies;            
            proxObj.cmdLUT = cmdLUT;
            proxObj.slTarget = slTarget;
        end

        function addPartner(proxObj, partnerProxObj)
        end

        function addTarget(proxObj, targetProxy)
        end

        function startDataStream(proxObj)
        end

        function startCapture(proxObj) % initiate capture protocol that stores a running datastream to associated DTS
        end

        function endCapture(proxObj) % end capture protocol
        end

        function writeToDTS(proxObj) % recieve a datagram and assign to associated DTS
        end

        function sessionLabelChanged(proxObj)
        end

        function readAllTargets()
        end

        function writeAllTargets()
        end


    end

end