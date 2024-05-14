function readDataFcn_photon(params, sgSrv, modSrv)
    disp("PV command received from Speedgoat.")
    PVcmd = read(sgSrv,sgSrv.NumBytesAvailable,"uint8"); 
    PVrx = zeros(25,1);   
    % localDataPath = params.paths.Data.RAW.PHOTON.local;
    localDataPath = "E:\photonTmp";
    projPresetsPath = "C:\ProgramData\Bruker Fluorescence Microscopy\Prairie View\5.8.64.700\Configuration\Environments";
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
            case 1 % GetImage | -gi
                scriptCmd = sprintf("-SetFileIteration %d",10);
                modSrv.SendScriptCommands(scriptCmd);
                modSrv.GetImage(1);
            case 2 % play TSeries | -ts
                cmdVal = PVcmd(PVidx);
                switch cmdVal
                    case 1 % run PRE tseries                        
                        delay = 65; % in future retrieve this from the env if possible                        
                    case 2 % run POST tseries                                     
                        delay = 130;                        
                end               
                % run 
                modSrv.SendScriptCommands("-ts");
                % return 
                PVrx_del = zeros(size(PVrx,1),1);                  
                PVrx_del(PVidx) = 1;
                delayCmdReturn(sgSrv, PVrx_del, delay);
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
                modSrv.SendScriptCommands(sprintf("-le '%s'",tsDefPath));                     
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
            case 5 % Close Shutter
                % modSrv.SendScriptCommands("-SetHardShutter Close")
                % delay = 3;               
                % PVrx_del = zeros(size(PVrx,1),1);                
                % PVrx_del(PVidx) = 1;
                % delayCmdReturn(sgSrv, PVrx_del, delay);                                
            case 6 % DEBUG
                scriptCmd = sprintf("-Get");
                modSrv.SendScriptCommands(scriptCmd);
                modSrv.SendScriptCommands("-gts");
            case 10 % ABORT
                modSrv.SendScriptCommands("-stop");
        end
    end

    write(sgSrv,uint8(PVrx))

end