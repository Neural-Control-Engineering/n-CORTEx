function writeDataFcn_photon(src, commandID)
    disp("writing data to server")
    % src.UserData = read(src,src.NumBytesAvailable,"uint8");
    % readline(src);
    % switch_expression = src.UserData;
    switch commandID
        case 0
            disp("Do nothing");              
        case 1
            DemoRemoteAPI;
            return
        otherwise
            disp("otherwise");
    end

end