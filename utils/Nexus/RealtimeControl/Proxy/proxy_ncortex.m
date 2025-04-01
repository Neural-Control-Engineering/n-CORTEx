classdef proxy_ncortex < handle
    % ncortex proxy to facilitate direct host-target transmissions,
    % experimental configuration protocols, and session data extraction pipeline management
    properties
        classID = "ncortex"
        partnerProxies      
        nCORTEx % a handle on the main ncortex application
        Server % tcp server that receives and sends transmissions from the main slrt process (happening on realtime computer, typiclly remote)        
        Client % tcp client 
        cmdLUT
        tgProxies; % handles to proxies associated with peripheral  target devices (spikeGl, prairielink, etc.)
        DTS
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_ncortex(ipAddress, portAddress, DTS, nCORTEx, tgProxies)
            proxObj.tgProxies = tgProxies;
            proxObj.DTS = DTS;
            proxObj.cmdLUT = cmdLUT;
            proxObj.nCORTEx = nCORTEx;
        end

        function transmitField(proxObj, key, value) % send either host to target or vice versa datafields 
        end

        function receiveField(proxObj) % receive (host to target or vice versa) datafields and update application accordingly             
            % NOTE: (if value is -1, assume this is an event callback rather than a datafield) 
            % decode key and value

            % execute key/value-specific callback 
        end

        function sessionLabelChanged(proxObj)
            % update nCORTEx and invoke sessionLabelChanged method on all
            % associated tgProxies
        end
    end

end