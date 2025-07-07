classdef proxy_ncortex < handle
    % ncortex proxy to facilitate direct host-target transmissions,
    % experimental configuration protocols, and session data extraction pipeline management
    properties
        proxon
        proxyID = "ncortex"
        type=1
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
            configureTerminator(proxObj.Server, "CR/LF");
            proxObj.Targets = tgProxies;
            proxObj.DTS = DTS;
            % proxObj.ctxKey = ctxKey;
            proxObj.nCORTEx = nCORTEx;
        end

        function configureSubject(proxObj)
            tgProxies = proxObj.proxon.index_type2;
            tgProxFields = fieldnames(tgProxies);
            for i = 1:length(tgProxFields)
                tgProxFN = tgProxFields{i};
                tgProxies.(tgProxFN).configureSubject();
            end
        end

        function openControlPanel(proxObj)            
            relayToTargetProxies(proxObj,"openControlPanel",[],[]);
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
                write(proxObj.Server,uint8(0));
                pause(0.5);
                % waitForReturn(proxObj.Server, 0, 0);
                % app-relative subassignment of transmitted values            
                % decode command
                % recover method arguments
                timer = 0;
                timeout = 5;
                delay=0.1;
                while true
                    if timer > timeout
                        disp("transmission timeout: please try again")
                        write(proxObj.Server,3);
                        flush(proxObj.Server);
                        break
                    end
                    % if proxObj.Server.NumBytesAvailable <= 0                        
                    %     % wait until data is recieved
                    
                    if proxObj.Server.NumBytesAvailable > 0                        
                        dataRx = read(proxObj.Server, proxObj.Server.NumBytesAvailable,"uint8");
                        try
                            rxArgs = getArrayFromByteStream(uint8(dataRx));
                            % execute method
                            proxObj.(methodID)(rxArgs);
                            disp("command complete");
                            write(proxObj.Server,uint8(1));                        
                            flush(proxObj.Server);
                            break
                        catch e
                            % disp(getReport(e));
                            disp("command failed");
                            write(proxObj.Server,2);
                            flush(proxObj.Server);                            
                        end                        
                    end                   
                    pause(delay);
                    timer = timer+delay;
                    disp(timer);
                end                
                
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

        function addPartner(proxObj, partnerProxObj)
            % share primary peripherals
            partnerProxObj.Targets = proxObj.Targets;
            partnerProxObj.DTS = proxObj.DTS;
        end

        function discardSession(proxObj, rxArgs)            
            session2Discard = rxArgs;
            uploadRaw(proxObj.nCORTEx.params.paths.Data.RAW,session2Discard,1);
        end

        function migrateTmp(proxObj, rxArgs)
        end

        function updateSessionLabel(proxObj, rxArgs)
            % update nCORTEx and invoke sessionLabelChanged method on all
            % associated tgProxies
            sessionLabel = rxArgs.sessionLabel;
            proxObj.nCORTEx.params.sessionLabel = sessionLabel;
            % apply sessionLabelChanged for each target proxy            
            targetProxyNames = fieldnames(proxObj.proxon.index_type2);
            % tgProxyNames = fieldnames(proxObj.Targets)
            for i = 1:length(targetProxyNames)
                tgProxyName = targetProxyNames{i};
                % call sessionLabel handle
                tgProxObj = proxObj.proxon.index_type2.(tgProxyName);
                try
                    tgProxObj.updateSessionLabel(sessionLabel)
                catch e
                    disp(getReport(e));
                end
            end
        end

        function assignField(proxObj, rxArgs)
            fieldPath = rxArgs.fieldPath;
            value = rxArgs.Value;
            fields = convertStringsToChars(strsplit(fieldPath, "--"));
            subField0 = fields{1};
            S = struct('type', '.', 'subs', fields);
            s=struct;
            s_subasgn = subsasgn(s, S, value);
            proxObj.nCORTEx.(subField0)=mergeStructs(proxObj.nCORTEx.(subField0), s_subasgn.(subField0));
            % proxObj.nCORTEx = subAssign(proxObj.nCORTEx, subFields, subFields{1}, value)
            % proxObj.nCORTEx = safeSetNestedField(proxObj.nCORTEx, fieldPath, value, '--');
        end

        function updateField(proxObj, rxArgs)
            % Automated remote host-target entry updates
            % fieldID
            fieldID = rxArgs.fieldID;
            % entryType = rxArgs.entryType;
            if isfield(rxArgs,"Value")
                proxObj.nCORTEx.(fieldID).Value = rxArgs.Value;
                try
                    % proxObj.nCORTEx.(fieldID).ValueChangedFcn([], app);
                    proxObj.nCORTEx.(fieldID).ValueChangedFcn(proxObj.nCORTEx,[]);
                catch e
                    disp(getReport(e));
                end
            end
            if isfield(rxArgs,"Items")
                proxObj.nCORTEx.(fieldID).Items = rxArgs.Items;
            end
            % entry = rxArgs.Value;
            % try
            %     proxObj.nCORTEx.(fieldID).(entryType) = entry;
            %     switch entryType
            %         case "Value"
            %             proxObj.nCORTEx.(fieldID).ValueChangedFcn([], app);
            %         case "Items"
            %         otherwise
            %     end
            % 
            % catch e
            %     disp(getReport(e));
            % end
        end

        function closeAllRealtimeThreads(proxObj, rxArgs)
            relayToTargetProxies(proxObj, "closeAllRealtimeThreads", rxArgs, []);
        end
    end

end