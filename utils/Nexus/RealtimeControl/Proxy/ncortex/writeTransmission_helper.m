function writeTransmission_helper(cortexClient, methodID, txArgs)
    % Send a methodID + serialized payload to a proxy_ncortex Server.
    %
    % Protocol: send the methodID line, wait for the ack, then send the
    % serialized payload as ONE contiguous byte stream and wait for a 1-byte
    % status code. The receiver (relayTransmission) ACCUMULATES bytes until the
    % stream deserializes, so we send exactly ONCE and never resend — resending
    % appended a second copy onto the receiver's buffer and corrupted the stream
    % so it could never assemble (the "command failed" storm).
    %
    % Status codes (1 byte, uint8): 1 = success, 2 = receiver method errored,
    % 3 = receiver idle-timeout.
    writeline(cortexClient, methodID);
    waitForReturn(cortexClient, 0, 1);            % consume the methodID ack (0)

    byteStream = getByteStreamFromArray(txArgs);
    write(cortexClient, uint8(byteStream));       % send payload once

    timer   = 0;
    timeout = 10;
    delay   = 0.1;
    while true
        if timer > timeout
            disp("transmission timeout: please try again");
            break
        end
        if cortexClient.NumBytesAvailable > 0
            txReturn = read(cortexClient, 1, "uint8");
            switch txReturn
                case 1
                    disp("transmission successful");
                    flush(cortexClient);
                    break
                case 2
                    disp("transmission failed: receiver method errored");
                    flush(cortexClient);
                    break
                case 3
                    disp("transmission failed: receiver timed out");
                    flush(cortexClient);
                    break
            end
        end
        pause(delay);
        timer = timer + delay;
    end
end
