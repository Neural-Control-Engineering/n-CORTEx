function npx = server_npxls(params)
    hostName = params.hostName;
    npx = [];
    switch hostName
        case 'DESKTOP-MRI7THQ'
            address = '169.254.149.124';
            modality = 'npxls';
            if ~isSGLX; npx = SpikeGL(address); end
    end
    % pl = actxserver('PrairieLink64.Application');
    % system('C:\SpikeGLX\Release_v20231207-phase30\SpikeGLX\SpikeGLX.exe')
    
    
    % npx = [];

end