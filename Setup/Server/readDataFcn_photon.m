function readDataFcn_photon(params, sgSrv, modSrv)
    disp("PV command received from Speedgoat.")
    PVcmd = read(sgSrv,sgSrv.NumBytesAvailable,"uint8"); 
    PVrx = zeros(25,1);   
    localDataPath = params.paths.Data.RAW.PHOTON.local;
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
                modSrv.SendScriptCommands(sprintf("-p %s",fullfile(localDataPath,params.sessionLabel)));
                % modSrv.SendScriptCommands(sprintf("-SetFileName %s",params.sessionLabel));
                modSrv.SendScriptCommands("-ts");
                delay = 60;               
                PVrx_del = zeros(size(PVrx,1),1);                
                PVrx_del(PVidx) = 1;
                delayCmdReturn(sgSrv, PVrx_del, delay);                                
            case 3 % Open Shutter
                modSrv.SendScriptCommands("-SetHardShutter Open")
                delay = 1;               
                PVrx_del = zeros(size(PVrx,1),1);                
                PVrx_del(PVidx) = 1;
                delayCmdReturn(sgSrv, PVrx_del, delay);                                
            case 4 % Close Shutter
                modSrv.SendScriptCommands("-SetHardShutter Close")
                delay = 3;               
                PVrx_del = zeros(size(PVrx,1),1);                
                PVrx_del(PVidx) = 1;
                delayCmdReturn(sgSrv, PVrx_del, delay);                                
            case 7 % DEBUG
                scriptCmd = sprintf("-Get");
                modSrv.SendScriptCommands(scriptCmd);
                modSrv.SendScriptCommands("-gts");
        end
    end

    write(sgSrv,uint8(PVrx))

end