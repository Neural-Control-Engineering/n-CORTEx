function params = setExtractionParams(opts)

    if isunix
        hostName = getenv("USER");
        if ~isfield(opts,'hostName'), opts.hostName=hostName; end
        if ~isfield(opts,'paths'), opts.paths=struct; end
        if ~isfield(opts.paths,'stem'), opts.paths.stem=fullfile("/home",hostName); end    
        if ~isfield(opts.paths,'NECdrive_cloud'), opts.paths.NECdrive_cloud = fullfile(opts.paths.stem,"NEC_Drive"); end                       
    elseif ispc
        hostName = getenv("COMPUTERNAME");
        if ~isfield(opts,'hostName'), opts.hostName=hostName; end
        if ~isfield(opts,'paths'), opts.paths=struct; end
        if ~isfield(opts.paths,'stem'), opts.paths.stem=fullfile("C:"); end
        if ~isfield(opts.paths,'NECdrive_cloud'), opts.paths.NECdrive_cloud = fullfile("I:\My Drive\Projects"); end       
    end      

    % if ~isfield(opts.paths,"Code_Repo"); end
    %% MISC
    if ~isfield(opts,"sampleRange"); opts.sampleRange = struct; end
    if ~isfield(opts.sampleRange,"target"); opts.sampleRange.target="all"; end
  
    %% Extraction config    
    if ~isfield(opts,"extractCfg"); opts.extractCfg = struct; end
    if ~isfield(opts.extractCfg,"dataStoreCfg"); opts.extractCfg.dataStoreCfg = struct; end
    if ~isfield(opts.extractCfg.dataStoreCfg,"blockSize"); opts.extractCfg.dataStoreCfg.blockSize = 100; end
    if ~isfield(opts.extractCfg,"experiment"); opts.extractCfg.experiment="JOLT"; end
    if ~isfield(opts.extractCfg,"EN"); opts.extractCfg.EN = struct; end
    if ~isfield(opts.extractCfg,"npxls"); opts.extractCfg.npxls = struct; end
    if ~isfield(opts.extractCfg.npxls,"numProbes"); opts.extractCfg.npxls.numProbes =2; end    
    if ~isfield(opts.extractCfg.npxls,"downSamp_lfp"); opts.extractCfg.npxls.downSamp_lfp = 5; end
    if ~isfield(opts.extractCfg,"LFP"); opts.extractCfg.LFP=struct; end
    if ~isfield(opts.extractCfg.LFP,"downSamp"); opts.extractCfg.LFP.downSamp = 5; end
    if ~isfield(opts.extractCfg.LFP,"Fs"); opts.extractCfg.LFP.Fs = 2500; end
    if ~isfield(opts.extractCfg.LFP,"Fs_downSamp"); opts.extractCfg.LFP.Fs_downSamp = 500; end
    if ~isfield(opts.extractCfg.LFP,"reset"); opts.extractCfg.LFP.reset=0; end
    if ~isfield(opts.extractCfg,"AP"); opts.extractCfg.AP=struct; end
    if ~isfield(opts.extractCfg.AP,"reset"); opts.extractCfg.AP.reset=0; end
    if ~isfield(opts.extractCfg.AP,"resetTrigs"); opts.extractCfg.AP.resetTrigs=0; end
    if ~isfield(opts.extractCfg,"behavior"); opts.extractCfg.behavior = struct; end
    if ~isfield(opts.extractCfg,"SLRT"); opts.extractCfg.SLRT = struct; end
    if ~isfield(opts.extractCfg.SLRT,"experiment"); opts.extractCfg.SLRT.experiment = "JOLT"; end
    if ~isfield(opts.extractCfg.SLRT,"reset"); opts.extractCfg.SLRT.reset = 0; end

    %% Spectral Band Ranges
    if ~isfield(opts,'bands'); opts.bands = struct; end % specify frequency band ranges in format [low, high]
    if ~isfield(opts.bands,'delta'); opts.bands.delta = [1, 4]; end  % 1 - 4 Hz
    if ~isfield(opts.bands,'theta'); opts.bands.theta = [4, 10]; end % 4 - 10 Hz
    if ~isfield(opts.bands,'alpha'); opts.bands.alpha = [10, 15]; end % 10 - 15 Hz
    if ~isfield(opts.bands,'beta'); opts.bands.beta = [15, 30]; end % 15 - 30 Hz
    if ~isfield(opts.bands,'gamma'); opts.bands.gamma = [30, 50]; end % 30 - 100 Hz

    %% Fieldtrip config (preprocessing)
    if ~isfield(opts, "ftCfg_preproc"); opts.ftCfg_preproc = struct; end
    if ~isfield(opts.ftCfg_preproc,"channel"); opts.ftCfg_preproc.channel = 'all'; end

    %% Fieldtrip config (mtmfft)
    if ~isfield(opts, "ftCfg_mtmfft"); opts.ftCfg_mtmfft = struct; end
    if ~isfield(opts.ftCfg_mtmfft,"method"); opts.ftCfg_mtmfft.method = 'mtmfft'; end
    if ~isfield(opts.ftCfg_mtmfft,"output"); opts.ftCfg_mtmfft.output = 'pow'; end
    if ~isfield(opts.ftCfg_mtmfft,"foi"); opts.ftCfg_mtmfft.foi = [0.3 : 0.1 : 40]; end
    if ~isfield(opts.ftCfg_mtmfft,"taper"); opts.ftCfg_mtmfft.taper = 'dpss'; end
    if ~isfield(opts.ftCfg_mtmfft,"tapsmofrq"); opts.ftCfg_mtmfft.tapsmofrq = [2]; end
    if ~isfield(opts.ftCfg_mtmfft,"keeptrials"); opts.ftCfg_mtmfft.keeptrials = 'yes'; end

    %% Fieldtrip config (mtmconvol)
    if ~isfield(opts, "ftCfg_mtmconvol"); opts.ftCfg_mtmconvol = struct; end
    if ~isfield(opts.ftCfg_mtmconvol,"method"); opts.ftCfg_mtmconvol.method = 'mtmconvol'; end
    if ~isfield(opts.ftCfg_mtmconvol,"output"); opts.ftCfg_mtmconvol.output = 'pow'; end
    if ~isfield(opts.ftCfg_mtmconvol,"foi"); opts.ftCfg_mtmconvol.foi = [0.3 : 0.1 : 40]; end
    if ~isfield(opts.ftCfg_mtmconvol,"t_ftimwin"); opts.ftCfg_mtmconvol.t_ftimwin = 4 ./ opts.ftCfg_mtmconvol.foi; end
    if ~isfield(opts.ftCfg_mtmconvol,"toi"); opts.ftCfg_mtmconvol.toi = [0:0.01:10]; end
    if ~isfield(opts.ftCfg_mtmconvol,"taper"); opts.ftCfg_mtmconvol.taper = 'hanning'; end
    if ~isfield(opts.ftCfg_mtmconvol,"tapsmofrq"); opts.ftCfg_mtmconvol.tapsmofrq = [2]; end     

    %% Fieldtrip config (specParams)
    if ~isfield(opts,'ftCfg_fooof'); opts.ftCfg_fooof = struct; end
    if ~isfield(opts.ftCfg_fooof,'method'); opts.ftCfg_fooof.method = 'mtmfft'; end
    if ~isfield(opts.ftCfg_fooof,'output'); opts.ftCfg_fooof.output = 'fooof'; end
    if ~isfield(opts.ftCfg_fooof,'export'); opts.ftCfg_fooof.export = 1; end    
    % if ~isfield(opts.ftCfg_fooof,'tapsmofrq'); opts.ftCfg_fooof.tapsmofrq= 2.857; end
    if ~isfield(opts.ftCfg_fooof,'tapsmofrq'); opts.ftCfg_fooof.tapsmofrq= 2; end
    if ~isfield(opts.ftCfg_fooof,'foilim'); opts.ftCfg_fooof.foilim= [0.3 50]; end % bandpass 0.3 to 40 Hz
    if ~isfield(opts.ftCfg_fooof,'pad'); opts.ftCfg_fooof.pad= 2; end

    %% Fieldtrip config (databrowser)
    if ~isfield(opts, "ftCfg_databrws"); opts.ftCfg_databrws = struct; end
    if ~isfield(opts.ftCfg_databrws,"viewmode"); opts.ftCfg_databrws.viewmode = 'vertical'; end
    if ~isfield(opts.ftCfg_databrws,"continuous"); opts.ftCfg_databrws.continuous = 'yes'; end
    if ~isfield(opts.ftCfg_databrws,"blocksize"); opts.ftCfg_databrws.blocksize = 4; end

    %% Gif Config
    if ~isfield(opts, 'gifCfg'); opts.gifCfg = struct; end
    if ~isfield(opts.gifCfg, 'frameDelay'); opts.gifCfg.frameDelay = 0.2; end % frame delay is 0.2 seconds
    if ~isfield(opts.gifCfg, 'filename'); opts.gifCfg.filename = fullfile(cd,'gifDemo.gif'); end

    %% Npxls Acquisition metadata    
    if ~isfield(opts,'aqcuisition'); opts.acquisition = struct; end
    if ~isfield(opts.acquisition,'Fs_lfp'); opts.acquisition.Fs_lfp = 2500; end
    if ~isfield(opts.acquisition,'Fs_ap'); opts.acquisition.Fs_ap = 30000; end
    % if ~isfield(opts.acquisition,'chanMap'); opts.acquisition.chanMap = load("neuropixPhase3A_kilosortChanMap.mat",'chanMap').chanMap; end
    % if ~isfield(opts.acquisition,'connected'); opts.acquisition.connected = load("neuropixPhase3A_kilosortChanMap.mat",'connected').connected; end
    % if ~isfield(opts.acquisition,'xcoords'); opts.acquisition.xcoords= load("neuropixPhase3A_kilosortChanMap.mat",'xcoords').xcoords; end
    % if ~isfield(opts.acquisition,'ycoords'); opts.acquisition.ycoords= load("neuropixPhase3A_kilosortChanMap.mat",'ycoords').ycoords; end
    if ~isfield(opts.acquisition,'npxWidth'); opts.acquisition.npxWidth = 4; end % npxlMtrx width is 4 channels to a row
    if ~isfield(opts.acquisition,'npxLength'); opts.acquisition.npxLength = 384; end
    
    % COMPUTER PARAMS
    switch opts.hostName
        case 'DESKTOP-MRI7THQ'
            opts.staticColor = [0.31,0.94,0.46];
            opts.ethernetIP = "128.59.150.93";
            opts.paths.NECdrive_cloud = fullfile("G:\My Drive\Projects");    
        case 'USERBRU-2FNENOI'
            opts.staticColor = [0.31,0.94,0.46];
            opts.ethernetIP = "128.59.87.69";
            opts.paths.NECdrive_cloud = fullfile("I:\My Drive\Projects");    
        case 'electro'
            opts.staticColor = [0.31,0.94,0.46];
            opts.ethernetIP = "127.0.0.1";
        case 'user'
            opts.staticColor = [0.31,0.94,0.46];
            opts.ethernetIP = "128.59.149.107";
        otherwise
            opts.staticColor = [0.31,0.94,0.46];

    end
    params = opts;

end