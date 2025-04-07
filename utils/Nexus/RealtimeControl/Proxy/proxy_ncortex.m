classdef proxy_ncortex < handle
    % ncortex proxy to facilitate direct host-target transmissions,
    % experimental configuration protocols, and session data extraction pipeline management
    properties
        proxyID = "ncortex"
        partnerProxies      
        nCORTEx % a handle on the main ncortex application
        Server % tcp server that receives and sends transmissions from the main slrt process (happening on realtime computer, typiclly remote)        
        Client % tcp client 
        cmdLUT
        Targets; % handles to proxies associated with peripheral  target devices (spikeGl, prairielink, etc.)
        DTS
    end
    
    methods
        
        % CONSTRUCTOR
        function proxObj = proxy_ncortex(nCORTEx, serverIP, serverPort, clientIP, clientPort, tgProxies, DTS, connectionChangedFcn)
            proxObj.Server = tcpserver(serverIP, serverPort,"ConnectionChangedFcn",@(src,event)connectionChangedFcn(src, event));
            proxObj.Targets = tgProxies;
            proxObj.DTS = DTS;
            % proxObj.ctxKey = ctxKey;
            proxObj.nCORTEx = nCORTEx;
        end

        function writeTransmission(proxObj, cmd, txArgs)
            byteStream = getByteStreamFromArray(payload);
            write(proxObj.Client, uint8(byteStream, "uint8"));
        end

        function relayTransmission(proxObj)
            dataRx = readline(proxObj.Server);
            % app-relative subassignment of transmitted values            
            % decode command
            % recover method arguments
            dataRx = read(proxObj.Server, proxObj.Server.NumBytesAvailable,"uint8");
            rxArgs = getArrayFromByteStream(uint8(dataRx));
            % execute method
            proxObj.(method)(rxArgs);
        end

        % function s = dynamicSetStruct(s, fieldPath, value)
        %     fields = strsplit(fieldPath, "--");
        %     S = struct('type', '.', 'subs', fields);
        %     s = subsasgn(s, S, value);
        % end

        function transmitField(proxObj, key, value) % send either host to target or vice versa datafields 
        end

        function receiveField(proxObj) % receive (host to target or vice versa) datafields and update application accordingly             
            % NOTE: (if value is -1, assume this is an event callback rather than a datafield) 
            % decode key and value

            % execute key/value-specific callback 
        end

        function discardSession(proxObj, rxArgs)
            
            session2Discard = rxArgs;
            uploadRaw(proxObj.nCORTEx.params.paths.Data.RAW,session2Discard,1);
        end

        function sessionLabelChanged(proxObj, rxArgs)
            % update nCORTEx and invoke sessionLabelChanged method on all
            % associated tgProxies
            sessionLabel = rxArgs;
            % apply sessionLabelChanged for each target proxy            
        end

        function assignPayload(proxObj, rxArgs)
            fieldPath = rxArgs.fieldPath;
            value = rxArgs.value;
            fields = strsplit(fieldPath, "--");
            S = struct('type', '.', 'subs', fields);
            s = subsasgn(s, S, value);
        end
    end

end