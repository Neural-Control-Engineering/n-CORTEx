function ctx_tx = ctxControl_TX(axon)
    % (de)compose control bus for tcp transmission (serialize)
    cmd = axon.CMD; % command vector    
    pl = axon.PL; % payload data
    sz = getPayloadSizes(pl);

    ctx_tx = [cmd_flat, sz_flat, pl_flat]; % uint8 serial transmission
end