classdef proxy_nexus < handle
    % ncortex proxy to facilitate direct host-target transmissions,
    % experimental configuration protocols, and session data extraction pipeline management
    properties
        proxyID = "nexus"
        Partners 
        nexon % a handle on the main ncortex application        
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_nexus(DTS, params)            
            proxObj.nexon = startNexus(params, DTS);
        end

    end

end