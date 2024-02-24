function readDataFcn_photon(params, sg, pl, ~)
    disp("PV command received from Speedgoat.")
    PVcmd_vector = read(sg,sg.NumBytesAvailable,"uint8");   
    dosomething = (PVcmd_vector(1) == 1);   
    switch dosomething 
        case dosomething
             % pl.GetState("dwellTime")
             isDone = pl.SendScriptCommands("-ts");
             write(sg,uint8(isDone));
             % sg.write(isDone);
        otherwise
            disp("otherwise");
    end

end