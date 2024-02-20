function readDataFcn_photon(sg, pl, ~)
    disp("PV command received from Speedgoat.")
    PVcmd_vector = read(sg,sg.NumBytesAvailable,"uint8");   
    dosomething = (PVcmd_vector(1) == 1);   
    switch dosomething
        case dosomething
             pl.GetState("dwellTime")
             sg.write("done")
        otherwise
            disp("otherwise");
    end

end