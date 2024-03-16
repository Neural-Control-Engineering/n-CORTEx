function npx = server_npxls(params)
    hostName = params.hostName;
    switch hostName
        case 'DESKTOP-MRI7THQ'
            address = '128.59.150.93';
            modality = 'npxls';
    end
    % pl = actxserver('PrairieLink64.Application');
    npx = SpikeGL(address);   

end