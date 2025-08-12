function axon_rx = ctxCtrl_RX(ctx_rx)
    numCmds = numel(enumeration('ctrlKey'));
    numBytes_sze = numCmds * 3; % three dimensions alloted per pyd    
    % (re)compose control bus for transmission return (de-serialize)    
    %% SPLICE TRANSMISSION
    cmd_rx = ctx_rx(1:numCmds); % first N bytes as cmd vector
    strt_sze = numCmds+1;
    sze_rx = ctx_rx(strt_sze:strt_sze+numBytes_sze-1);
    strt_pyd = strt_sze + numBytes_sze;
    numBytes_pyd = ctxCtrl_decodePayloadSize(sze_rx,3); % number of bytes expected in payload given payload sizes
    pyd_rx = ctx_rx(strt_pyd:end);
    % if numBytes_pyd > 0
    %     pyd_rx = ctx_rx(strt_pyd:strt_pyd+numBytes_pyd);
    % else
    %     pyd_rx = uint8(zeros(1,0));
    % end
    %% DESERIALIZE
    cmd_dsrl = ctxCtrl_deSerialize(cmd_rx,"CMD");
    sze_dsrl = ctxCtrl_deSerialize(sze_rx,"SZE");
    pyd_dsrl = ctxCtrl_deSerialize(pyd_rx,"PYD"); 
    %% ASSEMBLE AXON
    axon_rx.CMD = cmd_dsrl;
    axon_rx.SZE = sze_dsrl;
    axon_rx.PYD = pyd_dsrl;
end