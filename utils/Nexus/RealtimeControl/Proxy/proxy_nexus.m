classdef proxy_nexus < handle
    % ncortex proxy to facilitate direct host-target transmissions,
    % experimental configuration protocols, and session data extraction pipeline management
    properties
        proxyID = "nexus"
        Partners
        nCORTEx
        proxon
        nexon % a handle on the main ncortex application        
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_nexus(DTS, params)            
            proxObj.nexon = startNexus(params, DTS);
        end

        % function startCapture_lfp(proxObj)
        %     % use npxls proxy to capture lfp data
        %     relayToTargetProxies(proxObj,"startCapture_lfp",[],[]);
        % end
        % 
        % function startCapture_ap(proxObj)
        %     relayToTargetProxies(proxObj,"startCapture_ap",[],[]);
        % end

        function writeCapture(proxObj, DF)
            DFID = DF.dfID;
            dtsIdx = DF.dtsIdx;
            dtsIO_writeDF(proxObj.nexon, DF, DFID, dtsIdx);
        end

    end

end