classdef proxy_photon < handle
    properties
        proxon
        nCORTEx
        proxyID = "photon";               
        type=2
        Server
        compCfg
        nexFigures % handles to interactive figures
        stream
        writeBuffer
        readBuffer
        captureBuffer        
        EN_capStream
        EN_rtStream
        controlPanel     
        % axon_cmd = axon_build("command");
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_photon(serverIP, nCORTEx)            
            proxObj.Server = actxserver('PrairieLink64.Application');  
            proxObj.Server.Connect()
            proxObj.stream = timer("ExecutionMode","fixedRate","BusyMode","queue","Period",0.1,"TimerFcn",@(~,~)proxObj.readData);                        
            % application handle
            proxObj.nCORTEx = nCORTEx;
            % startup and configuration
            % proxObj.nCORTEx.params
            setupRepo = fullfile(proxObj.nCORTEx.nCORTEx_repo,"Setup","photon");
            proxObj.Server.SendScriptCommands("-spc");
            % proxObj.Server.SendScriptCommands(sprintf("-lspf %s", fullfile(setupRepo,"stage_default.xy")));
            % load general environment file
            % open control panel
            % proxObj.controlPanel = nexObj_controlPanel_photon([],proxObj.nCORTEx);
        end

        function configureSubject(proxObj)
            % load subject-specific env file
            % if none exists overwrite with current env
            ncortex = proxObj.nCORTEx;
            subjSel = ncortex.params.subject;
            path_projDirCloud = ncortex.params.paths.projDir_cloud;
            path_expDirCloud = fullfile(path_projDirCloud,"Experiments",ncortex.expmnt);
            path_subjDirCloud = fullfile(path_expDirCloud,"Subjects",subjSel);
            path_envFile = fullfile(path_subjDirCloud,"photon","environment.env");
            envExists = isfile(path_envFile);
            if envExists
                proxObj.Server.SendScriptCommands(sprintf("-le %s",path_envFile));
            else % save new (overwrite)
                proxObj.Server.SendScriptCommands(sprintf("-se %s",path_envFile));
            end            
        end

        function openControlPanel(proxObj, pyd, sze)
            proxObj.controlPanel = nexObj_controlPanel_photon([],proxObj.nCORTEx);
        end

        % FETCH DATA
        function readData(proxObj)
        end

        function writeData(proxObj)
        end

        % Z-Stack
        function zStack(proxObj)
            
        end

        % T-series
        function loadTSeries(proxObj, pyd, sze)
            % load t series def from env
            ncortex=proxObj.nCORTEx;
            expModulesPath = ncortex.params.paths.experimentModules;
            expModPath = fullfile(expModulesPath,ncortex.expmnt);
            tSeriesEnvPath = fullfile(expModPath,"photon/tseries_trigger_start_stop.env");
            proxObj.Server.SendScriptCommands(sprintf("-tsl %s",tSeriesEnvPath));
            % return 'complete'
            prxObj_slrt = proxObj.proxon.index_type1.slrt_2;

        end

        function startTSeries(proxObj, pyd, sze)
            disp("starting T-Series")
            proxObj.Server.SendScriptCommands("-ts");
        end

        function setSavePath(proxObj, pyd, sze)            
            % gX = extLogIO_gateNum(sessionLabel, experiment, ncortex.params.paths.projDir_cloud, ncortex.params.paths.projDir_local);
            % gated_sessionLabel = sprintf("%s_g%d", sessionLabel, gX);
            savePath = fullfile("E:/photonTmp");% locate E:/drive
            proxObj.Server.SendScriptCommands(sprintf("-p %s", savePath));
        end

        % function setAcquisitionType(proxObj, pyd, sze)
        % 
        % end

        function setFileName(proxObj, pyd, sze)
            ncortex = proxObj.nCORTEx;
            % proxObj.acquisitionType;
            sessionLabel = ncortex.params.sessionLabel;
            pyd_acquisitionType = pyd(1);
            acquisitionType = photonCtrl_decodeAcquisitionType(pyd_acquisitionType);
            % disp(acquisitionType);
            proxObj.Server.SendScriptCommands(sprintf("-fn %s %s", acquisitionType, sessionLabel));
        end

        function setFileIteration(proxObj, pyd, sze)            
            trialGateNum = pyd(1);
            acquisitionType = photonCtrl_decodeAcquisitionType(pyd(2));                       
            proxObj.Server.SendScriptCommands(sprintf("-fi %s %d", acquisitionType, trialGateNum));            
        end        

        % Open shuter
        function openShutter(proxObj)            
        end

        % close shutter
        function closeShutter(proxObj)
        end

        function sessionLabelChanged(proxObj)
        end

        function closeAllRealtimeThreads(proxObj, pyd, sze)
            proxObj.Server.SendScriptCommands(sprintf("-stop"));
        end

    end

end