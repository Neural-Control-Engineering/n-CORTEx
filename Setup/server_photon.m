function pl = server_photon(params)
    hostName = params.hostName;
    switch hostName
        case 'USERBRU-2FNENOI'
            address = "164.254.103.9";
            modality = 'photon';
    end
    pl = actxserver('PrairieLink64.Application');
    pl.Connect();

end