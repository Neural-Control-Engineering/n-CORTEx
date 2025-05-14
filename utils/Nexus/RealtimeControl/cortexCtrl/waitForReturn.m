function waitForReturn(Server, returnVal)
    timer = 0;
    timeout = 5;
    delay=0.1;
    while true
        if Server.NumBytesAvailable > 0
            rxData = read(Server,1);
            if rxData == returnVal
                write(Server, returnVal);
                disp("return successful, proceeding...")
                flush(Server);
                break
            else
                % empty and continue waiting (until timeout)
                flush(Server);
            end
        else
            if timer > timeout
                disp("return timeout: please try again");
                break
            end
            pause(delay);
            timer = timer+delay
        end        
    end
    
end