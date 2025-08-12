classdef proxy_nexus < handle
    % ncortex proxy to facilitate direct host-target transmissions,
    % experimental configuration protocols, and session data extraction pipeline management
    properties
        proxyID = "nexus"
        type=1
        Partners
        nCORTEx
        proxon
        nexon % a handle on the main ncortex application        
        controlPanel
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_nexus(nexon, nCORTEx, DTS, params)            
            % if isempty(nexon)
            %     proxObj.nexon = startNexus(params, DTS);
            % else
            %     proxObj.nexon = nexon;
            % end
            proxObj.nCORTEx=nCORTEx;
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
            % update nexDTS controlPanel
            proxObj.nexon.console.BASE.updateControlPanel();
        end

        function loadCapture(proxObj, dfType)
            % use nCORTEx handle to find and load dataframe into nexon
            switch dfType
                case "lfp"
                case "npxls"
                otherwise            
            end
        end

        function openControlPanel(proxObj)                        
            nexusCtrl_startNexus(proxObj);
            proxObj.controlPanel = nexObj_controlPanel_nexus(proxObj);
        end

    end

end