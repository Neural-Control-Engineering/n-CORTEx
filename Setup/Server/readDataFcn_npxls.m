function readDataFcn_npxls(params, sgSrv, modSrv)
    disp("PV command received from Speedgoat.")
    modSrv  = SpikeGL(char(params.ethernetIP));
    % PVcmd_vector = read(sgSrv,sgSrv.NumBytesAvailable,"uint8");   
    % dosomething = (PVcmd_vector(1) == 1);   
    %     disp("PV command received from Speedgoat.")
    PVcmd = read(sgSrv,sgSrv.NumBytesAvailable,"uint8"); 
    % flush(sgSrv);
    PVrx = zeros(25,1);   
    % localDataPath = params.paths.Data.RAW.PHOTON.local;
    localDataPath = "C:/npxlsTmp";    
    % tsTemp = 
    % dosomething = (PVcmd_vector(1) == 1);   
    % switch dosomething 
    %     case dosomething
    %          % pl.GetState("dwellTime")
    %          isDone = pl.SendScriptCommands("-ts");
    %          write(sg,uint8(isDone));
    %          % sg.write(isDone);
    %     otherwise
    %         disp("otherwise");
    % end
    cmdBuffer = find(PVcmd>=1);    
    
    for i = 1:length(cmdBuffer)
        PVidx = cmdBuffer(i);
        switch PVidx            
            case 1 % Fetch Data| -gi
                % [daqData,headCt] = Fetch( modSrv, js, ip, start_samp, max_samps, channel_subset, downsample_ratio )                
                a = GetStreamAcqChans(modSrv, 0, 0);
                a = GetStreamSaveChans(modSrv, 0, 0)
                mat = FetchLatest(modSrv, 2, 0, 2000);                
            case 2 % extract PSD
                % possible implementation here : cancel any other process /
                % stop all other timers
                % and 'switch' to PSD
                stream = timer;
                stream.ExecutionMode = 'fixedRate';
                stream.Period = 0.01; % 10 millisecond rate
                stream.TimerFcn = @(src, event)extractRT_bandPSD(sgSrv, modSrv, params.bands);
                start(stream);                
            case 3 % load TSeries PRE                
                cmdVal = PVcmd(PVidx);
                switch cmdVal
                    case 1 % run PRE tseries
                        % set pre
                        tsDefPath = fullfile(projPresetsPath,params.SelectProjectDirectoryDropDown,"PreTSeriesDefinition.env");                        
                        % delay = 65; % in future retrieve this from the env if possible
                        state="pre";
                    case 2 % run POST tseries
                        % set post
                        tsDefPath = fullfile(projPresetsPath,params.SelectProjectDirectoryDropDown,"PostTSeriesDefinition.env");                        
                        % delay = 130;
                        state="post";
                end
                delay=2;
                % load
                modSrv.SendScriptCommands(sprintf("-tsl '%s'",tsDefPath));                     
                % set t-series file name / location
                ssLbl = char(params.sessionLabel);
                % ssLbl = sprintf("%s-%s",state,ssLbl(1:40));
                modSrv.SendScriptCommands(sprintf("-p %s",fullfile(localDataPath,ssLbl)));
                fItr = length(dir(fullfile(localDataPath,ssLbl)))-1;
                modSrv.SendScriptCommands(sprintf("-fi TSeries %d",fItr));
                modSrv.SendScriptCommands(sprintf("-fn TSeries t"));
                % run 
                % modSrv.SendScriptCommands("-ts");
                % return 
                PVrx_del = zeros(size(PVrx,1),1);  
                PVidx = cmdBuffer(i);
                PVrx_del(PVidx) = 1;
                delayCmdReturn(sgSrv, PVrx_del, delay);
            case 4 % Open Shutter / Close Shutter
                cmdVal = PVcmd(PVidx);
                switch cmdVal
                    case 1 
                        modSrv.SendScriptCommands("-SetHardShutter Open")
                    case 2
                        modSrv.SendScriptCommands("-SetHardShutter Close")
                end
                % delay = 1;               
                % PVrx_del = zeros(size(PVrx,1),1);                
                % PVrx_del(PVidx) = 1;
                % delayCmdReturn(sgSrv, PVrx_del, delay);                                
            case 5 % Load Env
                cmdVal = PVcmd(PVidx);
                switch cmdVal
                    case 1 % load PRE ENV
                        envDefPath = fullfile(projPresetsPath,params.SelectProjectDirectoryDropDown,"PreTSeriesDefinition.env");                                            
                end
                modSrv.SendScriptCommands(sprintf("-le '%s'",envDefPath));                     
                % modSrv.SendScriptCommands("-SetHardShutter Close")
                % delay = 3;               
                % PVrx_del = zeros(size(PVrx,1),1);                
                % PVrx_del(PVidx) = 1;
                % delayCmdReturn(sgSrv, PVrx_del, delay);                                
            case 6 % DEBUG
                scriptCmd = sprintf("-Get");
                modSrv.SendScriptCommands(scriptCmd);
                modSrv.SendScriptCommands("-gts");
            case 7 % RTSTREAM
                fh = figure;
                plotFcn=[];
                Ax = axes('Parent',fh);     
                imgAx = imagesc('Parent',Ax,'CData',[])
                Ax.CLim = [-2.81224632263184,30.5982799530029]
                operationFcn = str2func("extractRT_STFT");
                % plotFcn = str2func("rtPlot_imagesc");
                lfpStream = rtStream(imgAx, sgSrv, modSrv, operationFcn, plotFcn)
                lfpStream.open()
                lfpStream.close();
            case 8 % RTSTREAM - 20 CHANS
                fh = figure;
                plotFcn = str2func("rtPlot_chansXfreqs");
                Ax = axes('Parent',fh);
                imgAx = imagesc('Parent',Ax,'CData',[]);
                % Ax.CLim = [-2.81224632263184,30.5982799530029];
                Ax.CLim = [-7.11224632263184,25.5982799530029];
                % Ax.CLim = [-7.11224632263184,17.5982799530029];
                operationFcn = str2func("extractRT_STFT");
                lfpStream = rtStream(imgAx, sgSrv, modSrv, operationFcn, plotFcn, [], 800);
                lfpStream.open();
                lfpStream.close();
            case 9 % RT STREAM - 40 CHANS plus 1-CHAN STFT
                fh = uifigure;
                fh.Position = [25,1260,1150, 600];
                ph1 = uipanel(fh);
                ph1.Position = [590,10,550,580];
                ph2 = uipanel(fh);
                ph2.Position = [10, 10, 550, 580];
                ax1 = axes('Parent',ph1);                
                imgAx1 = imagesc('Parent',ax1,'CData',[]);
                ax1.CLim = [-7.11224632263184,25.5982799530029];
                ax2 = axes('Parent',ph2);                
                imgAx2 = imagesc('Parent',ax2,'CData',[]);
                ax2.CLim = [-7.11224632263184,25.5982799530029];
                streamCfg.window = 1500;
                streamCfg.chanRange = [384:414];
                streamCfg.chanViewSel = 1;
                operationFcn = str2func("extractRT_STFT");
                plotFcn = str2func("rtPlot_chansXfreqs_freqsXtime");
                lfpStream = rtStream({imgAx1, imgAx2}, streamCfg, sgSrv, modSrv, operationFcn, plotFcn, []);
                lfpStream.open();                
                lfpStream.close();
                stop(lfpStream.timerObj)
            case 10 % RT STREAM - VIS OBJECT
                rtDash = struct;
                rtDash.fh = uifigure("Position",[25,1260,1150, 600],"Color",[0,0,0]);
                rtDash.panel1.ph = uipanel(rtDash.fh,"Position",[520,10,500,580],"BackgroundColor",[0,0,0]);
                rtDash.panel1.Ax = axes("Parent",rtDash.panel1.ph);
                rtDash.panel1.imgAx = imagesc(rtDash.panel1.Ax,"CData",[]);                
                rtDash.panel1.Ax.GridColor=[0.24,0.94,0.46];
                rtDash.panel1.Ax.Color=[0,0,0];
                rtDash.panel1.Ax.XColor=[0.24,0.94,0.46];
                rtDash.panel1.Ax.YColor=[0.24,0.94,0.46];
                rtDash.panel2.ph = uipanel(rtDash.fh,"Position",[10,10,500,580],"BackgroundColor",[0,0,0]);
                rtDash.panel2.Ax = axes("Parent",rtDash.panel2.ph,"Color",[0,0,0]);
                rtDash.panel2.surfAx = surf(rtDash.panel2.Ax,"CData",[]);
                rtDash.panel2.surfAx.EdgeColor="none";                
                rtDash.panel2.Ax.ZLim=[-10,25];
                rtDash.panel2.Ax.GridColor=[0.24,0.94,0.46];
                rtDash.panel2.Ax.Color=[0,0,0];
                rtDash.panel2.Ax.XColor=[0.24,0.94,0.46];
                rtDash.panel2.Ax.YColor=[0.24,0.94,0.46];
                rtDash.panel3.ph = uipanel(rtDash.fh,"Position",[1030,10,115,580],"BackgroundColor",[0,0,0]);
                rtDash.streamCfg.window = 1500;                
                rtDash.streamCfg.chanRange = [384:404];                
                rtDash.streamCfg.chanViewSel = 1;                
                rtDash.operationFcn = str2func("extractRT_STFT");
                rtDash.plotFcn = str2func("rtPlot_chansXfreqs_freqsXtime_surf");
                rtDash.rtStream = rtStream(rtDash, rtDash.streamCfg, sgSrv, modSrv, rtDash.operationFcn, rtDash.plotFcn, []);
                rtDash.panel3 = breakoutEntryFields(rtDash.panel3, rtDash.rtStream, rtDash.streamCfg);
                colormap(rtDash.fh,CT);
                % open stream
                rtDash.rtStream.open();
                % close stream
                rtDash.rtStream.close();
            case 11

            case 15 % ABORT
                modSrv.SendScriptCommands("-stop");
        end
    end

    write(sgSrv,uint8(PVrx))
end