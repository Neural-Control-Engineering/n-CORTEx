function readDataFcn_photon(sg, pl, ~)
    disp("Data was received from the client.")
    % src.UserData = read(src,src.NumBytesAvailable,"uint8");
    readline(sg);
    switch_expression = sg.UserData;
    switch switch_expression
        case "donothing"
            disp("Do nothing");
    
        case "querysglx"
            DemoRemoteAPI;
            return
        otherwise
            disp("otherwise");
    end

end