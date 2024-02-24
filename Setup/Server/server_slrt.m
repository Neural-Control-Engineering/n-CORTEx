function server = server_slrt(params, modalityServer)
    hostName = params.hostName;
    switch hostName
        case 'USERBRU-2FNENOI'
            address = "164.254.103.9";
            modality = 'photon';
    end
    readDataFcnHndl = str2func(sprintf('readDataFcn_%s',modality));
    connectionChangedFcnHndl = str2func(sprintf('connectionChangedFcn_%s', modality));
    server = tcpserver(address, 8001,"ConnectionChangedFcn",@(src,event)connectionChangedFcnHndl(modalityServer.Q));
    configureCallback(server,"byte",25,@(src, evnt)readDataFcnHndl(params,server,modalityServer.srv));    
end