function TX = cortexCtrl(cmd, args)
    % relay command and payload to tcp transmission
    cmdCode = ctrlKey.getCode(cmd); % first tcp (1 byte)
    % second tcp (N bytes)
    switch cmdCode
        % TARGET-FACING COMMANDS
        case "startDataStream" % relay target code
            payload = targetKey.getCode(args);
        case "stopDataStream"
            payload = targetKey.getCode(args);
        case "startCapture"
            payload = targetKey.getCode(args);
        case "stopCapture"
            payload = targetKey.getCode(args);
        otherwise % Default routine
            payload = [];
    end
    % transmit command and payload
    cmdTx = uint8(cmdCode);
    payloadTx = uint8(payload);
    % send command as first byte and subsequenct bytes as payload/args data
    TX = [cmdTx, payloadTx];

end