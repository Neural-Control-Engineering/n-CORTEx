function readDataFcn(src, ~)
    disp("Data was received from the client.")
    % src.UserData = read(src,src.NumBytesAvailable,"uint8");
    readline(src);
    switch_expression = src.UserData;
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