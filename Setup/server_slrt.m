function server = server_slrt(params, pl)
    hostName = params.hostName;
    switch hostName
        case 'USERBRU-2FNENOI'
            address = "164.254.103.9";
            modality = 'photon';
    end
    readDataFcnHndl = str2func(sprintf('readDataFcn_%s',modality));
    server = tcpserver(address, 8001)
    configureCallback(server,"byte",25,@(src, evnt)readDataFcnHndl(params, src,pl));
end