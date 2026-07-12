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
        % --- server lifecycle (recreate-on-drop / clean-teardown-on-disconnect) ---
        serverIP            % stored so a dropped listener can be rebuilt on the same bind
        serverPort
        appConnFcn          % app-level connection-changed callback (invoked with nCORTEx)
        userDisconnect = false % host set this via 'disconnect' cmd → tear down, do NOT recreate
        resetTimer          % one-shot timer; rebuilds/tears down the server outside its own callback
    end
    
    methods
        
        % CONSTRUCTOR
        function proxObj = proxy_ncortex(nCORTEx, serverIP, serverPort, clientIP, clientPort, tgProxies, DTS, connectionChangedFcn)
            proxObj.nCORTEx    = nCORTEx;
            proxObj.serverIP   = serverIP;
            proxObj.serverPort = serverPort;
            proxObj.appConnFcn = connectionChangedFcn;
            proxObj.Targets    = tgProxies;
            proxObj.DTS        = DTS;
            % proxObj.ctxKey = ctxKey;
            proxObj.buildServer();
        end

        % DESTRUCTOR — release the TCP server/client so the bound port is
        % freed on teardown. Without this the Server<->proxy callback cycle
        % keeps a stale tcpserver alive after the app closes, and the next
        % cortex("target") fails to re-bind (WSAEADDRINUSE on the same port).
        function delete(proxObj)
            proxObj.cancelResetTimer();
            if ~isempty(proxObj.Server)
                try, delete(proxObj.Server); catch, end
            end
            if ~isempty(proxObj.Client)
                try, delete(proxObj.Client); catch, end
            end
        end

        % (Re)create the tcpserver on the stored bind and wire its callbacks.
        % Safe to call after delete(Server) to recover a dropped link without
        % relaunching the app.
        function buildServer(proxObj)
            if ~isempty(proxObj.Server)   % idempotent: drop a prior bind before re-binding
                try, delete(proxObj.Server); catch, end
            end
            proxObj.Server = tcpserver(proxObj.serverIP, proxObj.serverPort, ...
                "ConnectionChangedFcn", @(src,event)proxObj.onServerConnChanged(src,event));
            configureCallback(proxObj.Server, "terminator", @(~,~)proxObj.relayTransmission());
            configureTerminator(proxObj.Server, "CR/LF");
        end

        % Server connection changed. Preserve the app-level UI callback, then
        % decide recovery: a fresh client connection needs nothing; a drop is
        % either an intentional host disconnect (userDisconnect → clean
        % teardown already armed) or an unexpected loss (→ rebuild a fresh
        % listener). Rebuild/teardown is deferred so we never delete the
        % tcpserver from inside its own callback.
        function onServerConnChanged(proxObj, src, ~)
            try, proxObj.appConnFcn(proxObj.nCORTEx); catch e, disp(getReport(e)); end
            if src.Connected, return; end          % a client just connected — nothing to recover
            if proxObj.userDisconnect
                proxObj.userDisconnect = false;    % consume the intent; teardown is already armed
                return;
            end
            proxObj.armOneShot(@()proxObj.resetServer());   % unexpected drop → recreate listener
        end

        % Host-initiated clean disconnect (relayed as a 'disconnect' command):
        % tear the listener down and do NOT recreate it. Deferred so we don't
        % delete the server from inside the relay/callback context.
        function disconnect(proxObj, ~)
            proxObj.userDisconnect = true;
            proxObj.armOneShot(@()proxObj.teardownServer());
        end

        function resetServer(proxObj)
            if ~isempty(proxObj.Server)
                try, delete(proxObj.Server); catch, end
            end
            proxObj.buildServer();
        end

        function teardownServer(proxObj)
            if ~isempty(proxObj.Server)
                try, delete(proxObj.Server); catch, end
            end
            proxObj.Server = [];
        end

        % Arm a single-shot timer that runs fcn shortly after the current
        % callback returns (so server delete/rebuild happens off the callback
        % stack). Replaces any previously armed timer.
        function armOneShot(proxObj, fcn)
            proxObj.cancelResetTimer();
            proxObj.resetTimer = timer("StartDelay",0.2,"ExecutionMode","singleShot", ...
                "TimerFcn",@(~,~)fcn());
            start(proxObj.resetTimer);
        end

        function cancelResetTimer(proxObj)
            if ~isempty(proxObj.resetTimer) && isvalid(proxObj.resetTimer)
                try, stop(proxObj.resetTimer);   catch, end
                try, delete(proxObj.resetTimer); catch, end
            end
            proxObj.resetTimer = [];
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

        function heartbeat(proxObj, rxArgs)
            % No-op liveness ping. The host sends this on a timer to keep the
            % idle-sensitive host->target link warm (NAT conntrack at the
            % routing gateway, campus ARP, Wi-Fi power save all age out on
            % idle — see startNcortexHeartbeat). relayTransmission acks success
            % automatically; nothing to do here but exist so the relay resolves
            % a real method instead of falling into its failure/timeout path.
        end
    end

end