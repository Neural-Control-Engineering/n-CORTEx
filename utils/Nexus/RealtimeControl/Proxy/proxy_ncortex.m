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
        % --- persistent command listener (adopt-on-relaunch) ---
        %   MATLAB's tcpserver cannot force-close a stale accepted connection,
        %   and delete() does not reliably free the bound port while a
        %   CLOSE_WAIT'd peer socket still occupies IP:port. So we bind this
        %   port exactly ONCE per MATLAB process and re-adopt the same listener
        %   on every relaunch, rather than delete+rebind (which fails with
        %   WSAEADDRINUSE). The listener keeps LISTENing across client
        %   disconnects, so a dropped host just reconnects.
        serverIP            % stored so the listener can be re-adopted on the same bind
        serverPort
        appConnFcn          % app-level connection-changed callback (invoked with nCORTEx)
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

        % DESTRUCTOR — release the outbound client only. The command LISTENER
        % is deliberately LEFT ALIVE (and left registered on groot) so the next
        % cortex("target") re-adopts it instead of rebinding. Deleting it here
        % would neither free the port (MATLAB won't release it while a dropped
        % peer socket lingers in CLOSE_WAIT) nor permit a clean re-bind next
        % launch — reuse is the only reliable path.
        function delete(proxObj)
            if ~isempty(proxObj.Client)
                try, delete(proxObj.Client); catch, end
            end
        end

        % ── Persistent command listener: adopt-or-bind ──────────────────────
        % Bind serverPort exactly once per MATLAB process; on every subsequent
        % relaunch re-adopt the live listener stashed on groot (groot appdata
        % survives app close and `clear all`) and just rewire its callbacks to
        % this proxy. We never delete+rebind: a tcpserver whose peer dropped
        % leaves an accepted socket in CLOSE_WAIT that MATLAB cannot force-close,
        % and that socket keeps IP:port occupied — so a fresh bind on the same
        % port fails with WSAEADDRINUSE no matter how long we back off. Reusing
        % the listener sidesteps the rebind entirely; the host simply reconnects.
        function buildServer(proxObj)
            key = proxObj.serverRegistryKey();
            existing = getappdata(groot, key);
            if ~isempty(existing) && isvalid(existing)
                proxObj.Server = existing;                 % re-adopt the live listener
            else
                proxObj.Server = tcpserver(proxObj.serverIP, proxObj.serverPort, ...
                    "ConnectionChangedFcn", @(src,event)proxObj.onServerConnChanged(src,event));
                setappdata(groot, key, proxObj.Server);    % durable handle for the next relaunch
            end
            % (Re)wire callbacks to THIS proxy — any prior owner is being torn down.
            proxObj.Server.ConnectionChangedFcn = @(src,event)proxObj.onServerConnChanged(src,event);
            configureCallback(proxObj.Server, "terminator", @(~,~)proxObj.relayTransmission());
            configureTerminator(proxObj.Server, "CR/LF");
        end

        % Process-durable registry key for this proxy's bound port. The listener
        % is stashed on groot under this key so a relaunch can find and re-adopt
        % it instead of rebinding (see buildServer).
        function key = serverRegistryKey(proxObj)
            key = sprintf("ncortexTcpServer_ncortex_%d", proxObj.serverPort);
        end

        % Server connection changed. Fire the app-level UI callback; no socket
        % recovery is needed either way — the persistent listener keeps
        % LISTENing across client disconnects and accepts the host's next
        % connection on its own. We deliberately do NOT delete/rebind on a drop
        % (see buildServer: rebinding this port is impossible while the dropped
        % peer socket lingers in CLOSE_WAIT).
        function onServerConnChanged(proxObj, ~, ~)
            try, proxObj.appConnFcn(proxObj.nCORTEx); catch e, disp(getReport(e)); end
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

        function transmitTrialRow(proxObj, rowStruct)
            % Host-side counterpart to receiveTrialRow. Send a trial "row" to
            % the target, where it merges into the DTS by (sessionLabel,
            % trialNumber). rowStruct must carry those two address fields plus
            % any data fields (field name -> DTS column name); build the trace
            % as a DF struct (.df + axis fields) so it sinks to HDF5 as array
            % data, and keep scalars (onset/withdrawal indices, scores) plain.
            if isempty(proxObj.Client)
                warning("ncortex:noClient", "no client connection; trial row not sent");
                return
            end
            writeTransmission_helper(proxObj.Client, "receiveTrialRow", rowStruct);
        end

        function receiveTrialRow(proxObj, rxArgs)
            % Merge a host-sent trial "row" (von Frey trace + meta) into the
            % target DTS, keyed by (sessionLabel, trialNumber). Each field of
            % rxArgs other than the address fields becomes its own dfID column
            % on that trial's row — array fields (e.g. the trace DF struct) sink
            % to HDF5 on export, scalar fields stay as manifest columns.
            %
            % rxArgs (struct) — required address fields + any data fields:
            %   .sessionLabel   char/string
            %   .trialNumber    numeric
            %   .<field> ...     e.g. vonfrey_trace (DF struct), vonfrey_onset,
            %                    vonfrey_withdrawal, withdrawalScore (scalars)
            nexon = proxObj.proxon.nexon;        % populated by nexusCtrl_startNexus
            if isempty(nexon)
                warning("ncortex:noNexon", "no nexon bound to proxon; trial row not stored");
                return
            end
            dtsIdx = struct('sessionLabel', rxArgs.sessionLabel, ...
                            'trialNumber',  rxArgs.trialNumber);
            dataFields = setdiff(fieldnames(rxArgs), {'sessionLabel','trialNumber'});
            for i = 1:numel(dataFields)
                f = dataFields{i};
                % forceMem=true: land on the same in-memory hybrid row the
                % neural capture created; disk flush happens on explicit sink.
                dtsIO_writeDF(nexon, rxArgs.(f), f, dtsIdx, true);
            end
            try
                nexon.console.BASE.updateControlPanel();
            catch e
                disp(getReport(e));
            end
        end

        function transmitDiscard(proxObj, sessionLabel, trialNumber)
            % Host-side: tell the target to drop a discarded trial's row.
            if isempty(proxObj.Client)
                warning("ncortex:noClient", "no client connection; discard not sent");
                return
            end
            rxArgs = struct('sessionLabel', sessionLabel, 'trialNumber', trialNumber);
            writeTransmission_helper(proxObj.Client, "discardTrial", rxArgs);
        end

        function discardTrial(proxObj, rxArgs)
            % Remove a discarded trial's row from the target DTS, keyed by
            % (sessionLabel, trialNumber), so it never clutters analysis.
            % Operates on the in-memory (pre disk-sink) row; a row already
            % flushed to HDF5 would also need its group pruned (later step).
            nexon = proxObj.proxon.nexon;
            if isempty(nexon)
                warning("ncortex:noNexon", "no nexon bound to proxon; discard skipped");
                return
            end
            dtsIdx = struct('sessionLabel', rxArgs.sessionLabel, ...
                            'trialNumber',  rxArgs.trialNumber);
            rowIdx = nex_searchRowAddress(nexon.console.BASE.DTS, dtsIdx);
            if isempty(rowIdx)
                fprintf("[proxy_ncortex] discardTrial: no row for %s trial %d\n", ...
                        string(rxArgs.sessionLabel), rxArgs.trialNumber);
                return
            end
            nexon.console.BASE.DTS(rowIdx,:) = [];
            try
                nexon.console.BASE.updateControlPanel();
            catch e
                disp(getReport(e));
            end
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

        % Fan the shutdown to every target proxy. Reached two ways with
        % different arity: closeProxies calls it as (pyd,sze) = ([],[]), while
        % the host command relay (relayTransmission) calls it as (rxArgs) — so
        % accept both. Targets' closeAllRealtimeThreads(pyd,sze) ignore the args.
        function closeAllRealtimeThreads(proxObj, pyd, sze)
            if nargin < 2, pyd = []; end
            if nargin < 3, sze = []; end
            relayToTargetProxies(proxObj, "closeAllRealtimeThreads", pyd, sze);
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