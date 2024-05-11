function readDataFcn_photon(params, sgSrv, modSrv)
    disp("PV command received from Speedgoat.")
    PVcmd = read(sgSrv,sgSrv.NumBytesAvailable,"uint8"); 
    PVrx = zeros(25,1);   
    localDataPath = params.paths.Data.RAW.PHOTON.local;
    projPresetsPath = "C:\ProgramData\Bruker Fluorescence Microscopy\Prairie View\5.8.64.700\Configuration\Environments";
    tsTemp = 
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
        switch cmdBuffer(i)
            case 1 % GetImage | -gi
                scriptCmd = sprintf("-SetFileIteration %d",10);
                modSrv.SendScriptCommands(scriptCmd);
                modSrv.GetImage(1);
            case 2 % TSeries | -ts
                cmdVal = PVcmd(2);
                switch cmdVal                   
                    case 1
                        modSrv.SendScriptCommands(sprintf("-p %s",fullfile(localDataPath,params.sessionLabel)));
                        % modSrv.SendScriptCommands(sprintf("-SetFileName %s",params.sessionLabel));
                        modSrv.SendScriptCommands("-ts");
                        delay = 60;               
                        PVrx_del = zeros(size(PVrx,1),1);                
                        PVrx_del(PVidx) = 1;
                        delayCmdReturn(sgSrv, PVrx_del, delay);                                
                    case 2
                end
            case 3 % play TSeries PRE                
                cmdVal = PVcmd(3);
                switch cmdVal
                    case 1 % run PRE tseries
                        % set pre
                        tsDefPath = fullfile(projPresetsPath,params.SelectProjectDirectoryDropDown,"PreTSeriesDefinition.env");                        
                        delay = 65; % in future retrieve this from the env if possible
                    case 2 % run POST tseries
                        % set post
                        tsDefPath = fullfile(projPresetsPath,params.SelectProjectDirectoryDropDown,"PostTSeriesDefinition.env");                        
                        delay = 130;
                end
                % load
                modSrv.SendScriptCommands(sprintf("-tsl '%s'",tsDefPath));                     
                % set t-series file name / location
                ssLbl = char(params.sessionLabel);
                ssLbl = ssLbl(1:10);
                modSrv.SendScriptCommands(sprintf("-p %s",fullfile(localDataPath,ssLbl)));
                % run 
                modSrv.SendScriptCommands("-ts");
                % return 
                delayCmdReturn(sgSrv, PVrx_del, delay);
            case 4 % Open Shutter
                modSrv.SendScriptCommands("-SetHardShutter Open")
                delay = 1;               
                PVrx_del = zeros(size(PVrx,1),1);                
                PVrx_del(PVidx) = 1;
                delayCmdReturn(sgSrv, PVrx_del, delay);                                
            case 5 % Close Shutter
                modSrv.SendScriptCommands("-SetHardShutter Close")
                delay = 3;               
                PVrx_del = zeros(size(PVrx,1),1);                
                PVrx_del(PVidx) = 1;
                delayCmdReturn(sgSrv, PVrx_del, delay);                                
            case 6 % DEBUG
                scriptCmd = sprintf("-Get");
                modSrv.SendScriptCommands(scriptCmd);
                modSrv.SendScriptCommands("-gts");
        end
    end

    write(sgSrv,uint8(PVrx))

end