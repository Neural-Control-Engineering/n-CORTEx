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
            proxObj.Server = tcpserver(serverIP, serverPort,"ConnectionChangedFcn",@(src,event)connectionChangedFcn(nCORTEx));
            configureCallback(proxObj.Server,"terminator",@(~,~)proxObj.relayTransmission());
            proxObj.Targets = tgProxies;
            proxObj.DTS = DTS;
            % proxObj.ctxKey = ctxKey;
            proxObj.nCORTEx = nCORTEx;
        end

        function writeTransmission(proxObj, methodID, txArgs)
            % method ID
            writeline(proxObj.Client,methodID);
            % payload
            byteStream = getByteStreamFromArray(txArgs);
            write(proxObj.Client, uint8(byteStream, "uint8"));
        end

        function relayTransmission(proxObj)
            try
                methodID = readline(proxObj.Server);
                % app-relative subassignment of transmitted values            
                % decode command
                % recover method arguments
                dataRx = read(proxObj.Server, proxObj.Server.NumBytesAvailable,"uint8");
                rxArgs = getArrayFromByteStream(uint8(dataRx));
                % execute method
                proxObj.(methodID)(rxArgs);
            catch e
               disp(getReport(e));
            end
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

        function migrateTmp(proxObj, rxArgs)
        end

        function sessionLabelChanged(proxObj, rxArgs)
            % update nCORTEx and invoke sessionLabelChanged method on all
            % associated tgProxies
            sessionLabel = rxArgs.sessionLabel;
            % apply sessionLabelChanged for each target proxy            
        end

        function updateProperty(proxObj, rxArgs)
            fieldPath = rxArgs.fieldPath;
            value = rxArgs.value;
            fields = strsplit(fieldPath, "--");
            S = struct('type', '.', 'subs', fields);
            s = subsasgn(s, S, value);
        end

        function updateField(proxObj, rxArgs)
            % Automated remote host-target entry updates
            appField = rxArgs.appField;
            entryType = rxArgs.entryType;
            entry = rxArgs.Value;
            try
                proxObj.nCORTEx.(appField).(entryType) = entry;
                switch entryType
                    case "Value"
                        proxObj.nCORTEx.(appField).ValueChangedFcn([], app);
                    case "Items"
                    otherwise
                end
                
            catch e
                disp(getReport(e));
            end
        end
    end

end