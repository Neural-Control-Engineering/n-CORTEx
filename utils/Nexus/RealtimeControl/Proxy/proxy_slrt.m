classdef proxy_slrt < handle
    % the slrt proxy is itself a proxy as well as a manager of each proxy
    % associated with a neural recording device 
    % it will mediate incoming and outgoing commands/transmissions to and
    % from a simulink realtime model that enables 1) online reading/writing
    % from target devices (neural recording/stimulating platforms, cameras,
    % actuators, peripheral instruments, etc.), 2) online compiling of
    % datastores for in-situ/human-in-the-loop analysis and 3) online
    % visualization of data streams as they are recorded and processed -
    % these capacities are distributed among the slrt proxy and its
    % associated target/device proxies
    properties
        proxon
        proxyID = "slrt"
        type=1
        Partners
        slTarget
        Server % transport layer server that receives and sends transmissions from the main slrt process (happening on realtime computer, typiclly remote)        
        Client % transport layer client 
        streamBuffer
        rxBuffer
        DF_rx
        compCfg
        nexFigures
        ctrlKey
        Targets; % handles to proxies associated with peripheral  target devices (spikeGl, prairielink, etc.)        
        % isCapturing=0;
        % isStreaming=0;
        numBytes_cmd = numel(enumeration('ctrlKey'));
        DTS
        axon
        Q % data queue for parallel interfacing (With other proxies)
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_slrt(serverIP, serverPort, clientIP, clientPort, slTarget, tgProxies, connectionChangedFcn)            
            proxObj.Server = tcpserver(serverIP, serverPort,"ConnectionChangedFcn",@(src,event)connectionChangedFcn(src, event));
            if ~isempty(clientIP)
                proxObj.Client = tcpclient(clientIP, clientPort, "ConnectionChangedFcn", @(src, event)connectionChangedFcn(src, event));                
            else
                proxObj.Client = [];
            end
            % configureCallback(proxObj.Server,"byte",1,@(src, evnt)proxObj.relayTransmission(params,server,modalityServer.modSrv));    
            % configureCallback(proxObj.Server,"byte",1,@(src, evnt)proxObj.relayTransmission(proxObj));    
            % numBytes_cmd = numel(enumeration('ctrlKey'));
            configureCallback(proxObj.Server,"byte",proxObj.numBytes_cmd,@(~,~)proxObj.relayTransmission());
            % instantiate axon (cmd)
            [ax, ax_struct] = axon_build("command");
            proxObj.axon = ax_struct;
            proxObj.Targets = tgProxies;            
            % proxObj.ctrlKey = ctrlKey();
            proxObj.slTarget = slTarget;
        end

        function relayTransmission(proxObj)            
            %% read command code (simple for now)
            % cmdCode = read(proxObj.Server,proxObj.Server.NumBytesAvailable,"uint8");       
            % proxObj.numBytes_cmd = numel(enumeration('ctrlKey'));
            % disp(proxObj.Server.NumBytesAvailable);
            try
                cmdCode = read(proxObj.Server,proxObj.Server.NumBytesAvailable,"uint8");    
            catch e
                disp("read failed");
                % disp(getReport(e));
                return
            end
            axon_rx = ctxCtrl_RX(cmdCode);
            CMD = axon_rx.CMD;
            % get command list
            CMD_sel = find(CMD~=0);
            % cmdIDs = arrayfun(@(cmd) ctxCtrl_decodeCommand(cmdSel), CMD, "UniformOutput",false);
            cmdIDs = arrayfun(@(cmd_sel) ctrlKey.getCmd(cmd_sel), CMD_sel, "UniformOutput",false)
            pyds = (arrayfun(@(cmd_sel) axon_rx.PYD(cmd_sel,:),CMD_sel, "UniformOutput",false));
            szes = (arrayfun(@(cmd_sel) axon_rx.SZE(cmd_sel,:),CMD_sel,"UniformOutput",false));
            cellfun(@(cmdID, pyd, sze) proxObj.(cmdID)(pyd, sze), cmdIDs, pyds, szes, "UniformOutput", false);
            % invoke methods (store return)
            % ctxCtrl_invokeCommand(@(cmdID) proxObj.(cmdID)(pyd));
            % return axon with selected command vectors as logic high
            proxObj.returnCommand(CMD_sel);
            % cmdCode = read(proxObj.Server,proxObj.numBytes_cmd,"uint8");             
            % cmdRx = uint8(zeros(25,1));
            % cmdBuffer = find(cmdCode>=1);
            % for i = 1:length(cmdBuffer)
            %     idx_cmd = cmdBuffer(i);
            %     switch idx_cmd
            %         case 7 % z-stack
            %             proxObj.proxon.index_type2.photon_2.zStack();                        
            %     end
            % end
            %% command lookup
            % command = proxObj.ctrlKey.getCmd(cmdCode);                                 
            % execute designated command (using corresponding target (e.g.
            % start datastream should initiate a subroutine that fetches
            % data from all targets))
            %% execute command
            % proxObj.(methodHandle);

        end

        function addPartner(proxObj, partnerProxObj)
            % share primary peripherals
            partnerProxObj.Targets = proxObj.Targets;
            partnerProxObj.DTS = proxObj.DTS;
        end

        function addTarget(proxObj, targetProxy)
        end

        function returnCommand(proxObj, CMD_sel)            
            axon_tx = proxObj.axon;
            CMD_tx = zeros(size(axon_tx.CMD));
            CMD_tx(CMD_sel) = 1;
            axon_tx.CMD = CMD_tx;            
            % NOTE FUTURE SHOULD RESET PYD AND SZE AS WELL
            ctx_tx = ctxCtrl_TX(axon_tx);
            proxObj.Server.write(ctx_tx);
        end

        function startDataStream(proxObj)
        end

        function startCapture(proxObj) % initiate capture protocol that stores a running datastream to associated DTS
            % retrieve target data (whatever's left in the transmission)
            targetCode = read(proxObj.Server,proxObj.Server.NumBytesAvailable,"uint8");
            targetID = targetKey.getTargetID(targetCode);
            % initialize target capStream

        end

        function endCapture(proxObj) % end capture protocol
            targetCode = read(proxObj.Server,proxObj.Server.NumBytesAvailable,"uint8");
            targetID = targetKey.getTargetID(targetCode);
            % end target capStream
        end        

        function writeToDTS(proxObj) % recieve a datagram and assign to associated DTS
        end

        function sessionLabelChanged(proxObj)
        end

        function readAllTargets(proxObj)
        end

        function writeAllTargets(proxObj)
        end

        function endOfTrial(proxObj)
        end

        function loadTSeries(proxObj, pyd, sze)
            relayToTargetProxies(proxObj, "loadTSeries", pyd, sze);            
        end

        function startTSeries(proxObj, pyd, sze)
            relayToTargetProxies(proxObj, "startTSeries", pyd, sze);
        end

        function setSavePath(proxObj, pyd, sze)
            relayToTargetProxies(proxObj, "setSavePath", pyd, sze);
        end

        function setFileIteration(proxObj, pyd, sze)
            relayToTargetProxies(proxObj, "setFileIteration", pyd, sze);
        end

        function setFileName(proxObj, pyd, sze)
            relayToTargetProxies(proxObj, "setFileName", pyd, sze);
        end   

        function captureDataStream_npxls(proxObj, pyd, sze)
            relayToTargetProxies(proxObj,"captureDataStream_npxls",pyd,sze);
            % relayToType1Proxies()
        end

        function transmitCapture_slrt(proxObj, pyd, sze)
            data_rx = pyd(2:end);
            txMode = pyd(1);
            switch txMode
                case 1 % buffer data
                    if diff([txMode, txMode_prev]) > 0
                        DF_rx.df = [];
                    else
                        proxObj.rxBuffer = [proxObj.rxBuffer,data_rx];
                    end
                case 2 % buffer label
                case 3 % write to nexon
                    proxObj.proxon.proxObjs.nexus_1.writeCapture(DF);
            end
            
        end

        % function startCapture_ap(proxObj, pyd, sze)
        %     relayToTargetProxies(proxObj,"startCapture_ap",pyd,sze);
        % end

        % function closeAllRealtimeThreads(proxObj, pyd, sze)
        %     % abort concurrent prairielink processes
        % end


    end

end