function ctx_tx = ctxCtrl_TX(axon_tx)
    % (de)compose control bus for tcp transmission (serialize)
    % cmd = axon.CMD; % command vector    
    % pl = axon.PYD; % payload data
    % sz = getPayloadSizes(pl);
    % cmd_flat = cmd'; % transpose cmd vector
    cmd_tcp = ctxCtrl_serialize(axon_tx.CMD,'CMD');
    sze_tcp = ctxCtrl_serialize(axon_tx.SZE,'SZE');
    pyd_tcp = ctxCtrl_serialize(axon_tx.PYD,'PYD');
    ctx_tx = [cmd_tcp, sze_tcp, pyd_tcp]; %  uint8 serial transmission
end

% Simulink.Bus.createMATLABStruct('axon')