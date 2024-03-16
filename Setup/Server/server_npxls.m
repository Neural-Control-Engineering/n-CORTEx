function npx = server_npxls(params)
    hostName = params.hostName;
    switch hostName
        case 'DESKTOP-MRI7THQ'
            address = "128.150.49.93";
            modality = 'npxls';
    end
    pl = actxserver('PrairieLink64.Application');
    pl.Connect();

end