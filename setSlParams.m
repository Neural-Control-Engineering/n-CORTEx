function params = setSlParams(opts)
    
    %% PATH PRESETS
    switch ispc
        case 1
            hostName = getenv('COMPUTERNAME');
        case 0
            hostName = getenv('USER');
    end
        
    if ~isfield(opts,'paths'), opts.paths=struct; end
       
    switch hostName
        case 'electro'
            if ~isfield(opts.paths,'nCORTEx_repo'), opts.paths.nCORTEx_repo = '/home/electro/Code_Repo/n-CORTEx'; end
            if ~isfield(opts.paths,'NECdrive_root'), opts.paths.NECdrive_root = '/home/electro/NEC_Drive'; end
        case 'genoma'
            if ~isfield(opts.paths,'nCORTEx_repo'), opts.paths.nCORTEx_repo = '/home/genoma/Code_Repo/n-CORTEx'; end
            if ~isfield(opts.paths,'NECdrive_root'), opts.paths.NECdrive_root = '/home/genoma/NEC_Drive'; end
    end

    if ~isfield(opts,'dataStream'),opts.dataStream=struct; end 
    if ~isfield(opts.dataStream,'Pupillometry'), opts.dataStream.Pupillometry=0; end
    if ~isfield(opts.dataStream,'Neuropixels'), opts.dataStream.Neuropixels=0; end
    if ~isfield(opts.dataStream,'Photometry'), opts.dataStream.Photometry=0; end
    if ~isfield(opts.dataStream,'Piezo'), opts.dataStream.Piezo=0; end
    
    params = opts;
    dsMask = params.dataStream;
    dsMask.pth = params.paths.nCORTEx_repo;
    save(fullfile(params.paths.nCORTEx_repo,'dsMask.mat'),'dsMask');
end