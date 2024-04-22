function readDataFcn_photon(params, sgSrv, modSrv)
    disp("PV command received from Speedgoat.")
    PVcmd_vector = read(sgSrv,sgSrv.NumBytesAvailable,"uint8");   
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
                
        end
    end

end