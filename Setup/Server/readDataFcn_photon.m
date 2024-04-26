function readDataFcn_photon(params, sgSrv, modSrv)
    disp("PV command received from Speedgoat.")
    PVcmd = read(sgSrv,sgSrv.NumBytesAvailable,"uint8"); 
    PVrx = zeros(25,1);
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
    cmdBuffer = find(PVcmd_vector==1);    
    
    for i = 1:length(cmdBuffer)
        switch cmdBuffer(i)
            case 1 % GetImage | -gi
                scriptCmd = sprintf("-SetFileIteration %d",10);
                modSrv.SendScriptCommands(scriptCmd);
                modSrv.GetImage(1);
            case 2 % TSeries | -ts                   
                modSrv.SendScriptCommands("-ts");                
            case 3 % Open Shutter
                modSrv.SendScriptCommands("-SetHardShutter Open")
            case 4 % Close Shutter
                modSrv.SendScriptCommands("-SetHardShutter Close")
                pause(1);
                
            case 7 % DEBUG
                scriptCmd = sprintf("-Get");
                modSrv.SendScriptCommands(scriptCmd);
                modSrv.SendScriptCommands("-gts");
        end
    end

    write(sgSrv,uint8(PVrx))

end