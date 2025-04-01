classdef proxy_nexus < handle
    % ncortex proxy to facilitate direct host-target transmissions,
    % experimental configuration protocols, and session data extraction pipeline management
    properties
        classID = "nexus"
        partnerProxies      
        nexon % a handle on the main ncortex application
        Server % tcp server that receives and sends transmissions from the main slrt process (happening on realtime computer, typiclly remote)        
        Client % tcp client 
        cmdLUT
        tgProxies; % handles to proxies associated with peripheral  target devices (spikeGl, prairielink, etc.)
        DTS
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_nexus(ipAddress, portAddress, DTS, nexon, tgProxies)
            proxObj.tgProxies = tgProxies;
            proxObj.DTS = DTS;
            proxObj.cmdLUT = cmdLUT;
            proxObj.nexon = nexon;
        end

    end

end