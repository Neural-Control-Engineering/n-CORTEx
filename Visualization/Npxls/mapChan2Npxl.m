function NpxlTnsr = mapChan2Npxl(params, chanMtrx)
    chanMap = params.acquisition.chanMap;
    connected = params.acquisition.connected;
    % xcoords = params.acquisition.xcoords;
    % ycoords = params.acquisition.ycoords;    
    npxW = params.acquisition.npxWidth;
    npxL = params.acquisition.npxLength;
    mtrxL = round(npxL/npxW);    
    % chanMap(connected==0)=[]; % remove unused channels
    
    % iterate along channels and assign to npxl matrix
    NpxlTnsr = [];
    for t = 1:size(chanMtrx,2)
        NpxlMtrx = nan(mtrxL,npxW); % initiate npxl matrix
        m=0;
        for i = 1:size(chanMap,1)
            chan = chanMap(i);
            col = mod(chan-1,npxW)+1;            
            % switch positions 2 and 3
            if col == 2
                col = 3;
            elseif col == 3
                col = 2; 
            end
            row = mtrxL - (floor((chan-1)/npxW));
            isConnect = connected(i);
            if isConnect
                m=m+1;
                NpxlMtrx(row,col) = chanMtrx(m,t);               
            end            
        end
        % smoothing to fill unused electrode channels
        NpxlMtrx = smoothMtrxHoles(NpxlMtrx);

        %% Truncate outside channels
        % outerTrunc=params.viewCfg.viewNT.outerTrunc;
        % NpxlMtrx = NpxlMtrx(outerTrunc:end,:);

        NpxlTnsr = cat(3,NpxlTnsr,NpxlMtrx);

        

    end
    

end