function server = server_slrt(params, modalityServer)
    hostName = params.hostName;
    modality = [];
    server = [];
    switch hostName
        case 'USERBRU-2FNENOI'
            address = "164.254.103.9";
            modality = 'photon';
        case 'DESKTOP-MRI7THQ'
            % address = "169.254.44.177";
            address = "169.254.91.65";
            modality = 'npxls';
    end
    if ~isempty(modality)
        readDataFcnHndl = str2func(sprintf('readDataFcn_%s',modality));
        connectionChangedFcnHndl = str2func(sprintf('connectionChangedFcn_%s', modality));
        server = tcpserver(address, 8002,"ConnectionChangedFcn",@(src,event)connectionChangedFcnHndl(modalityServer.Q));
        % configureCallback(server,"byte",25,@(src, evnt)readDataFcnHndl(params,server,modalityServer.modSrv));    
        configureCallback(server,"byte",25,@(src, evnt)readDataFcnHndl(params,server,modalityServer.modSrv));    
    end
end