function numBytes_pyd = ctxCtrl_decodePayloadSize(sze_rx, nDims)
    % steps = 
    numBytes_pyd = 0;
    for i = 1:nDims:length(sze_rx)-nDims
        ss = sze_rx(i:i+nDims-1);        
        % ss = ss(ss~=0);
        numBytes = prod(ss); 
        numBytes_pyd = numBytes_pyd + numBytes;
    end
end