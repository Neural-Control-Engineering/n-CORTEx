function writeTransmission_helper(cortexClient, methodID, txArgs)
    % method ID        
    writeline(cortexClient,methodID);
    waitForReturn(cortexClient, 0, 1);
    % while true
    %     if cortexClient.NumBytesAvailable > 0
    %         txReturn = read(cortexClient);
    %         if txReturn == 0   
    %             disp("methodID transmission successful, proceeding...")
    %             write(cortexClient,uint8(0));
    %             break
    %         end
    %     elseif timer > timeout
    %         disp("methodID transmission timeout; please try again");
    %         break
    %     end
    %     timer = timer+delay;
    % end
    % payload
    % pause(10)
    byteStream = getByteStreamFromArray(txArgs);
    write(cortexClient, uint8(byteStream));
    timer=0;
    timeout=10;
    delay=0.1;
    while true
        % txReturn = read(cortexClient)
        if timer>timeout
            % timer=0;            
            disp("transmission timeout: please try again");
            break
        end
        % if cortexClient.NumBytesAvailable <= 0
        %     % pause(0.1);
        %     timer=timer+delay;
        if cortexClient.NumBytesAvailable > 0
            txReturn = read(cortexClient)
            if txReturn == 1
                disp("transmisison successful");
                flush(cortexClient);
                break
                % disp(txReturn);                
            elseif txReturn == 2
                % try again
                % disp(txReturn);
                disp("transmission failed: trying again...");                
                write(cortexClient, uint8(byteStream))
                % flush(cortexClient);
            elseif txReturn == 3
                % disp(txReturn)
                disp("transmission failed: please try again");                
                write(cortexClient, uint8(byteStream))
                % flush(cortexClient);
            end            
        end
        pause(delay);
        timer=timer+delay;
        % flush(cortexClient);
    end
end