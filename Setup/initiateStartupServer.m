function cortexServer = initiateCortexServer(params)
    cortexServer = tcpserver(params.ethernetIP,8001);
    configureCallback(cortexServer,"terminator",str2func('startupServerCallback'));
end