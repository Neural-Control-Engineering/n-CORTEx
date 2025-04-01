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
        partnerProxies
        slTarget
        Server % tcp server that receives and sends transmissions from the main slrt process (happening on realtime computer, typiclly remote)        
        Client % tcp client 
        cmdLUT
        tgProxies; % handles to proxies associated with peripheral  target devices (spikeGl, prairielink, etc.)
        DTS
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_slrt(DTS, cmdLUT, slTarget, tgProxies)
            proxObj.tgProxies = tgProxies;
            proxObj.DTS = DTS;
            proxObj.cmdLUT = cmdLUT;
            proxObj.slTarget = slTarget;
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