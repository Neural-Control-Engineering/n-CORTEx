function params = setCortexParams(opts)
    
    %% PATH PRESETS
    switch ispc
        case 1
            hostName = getenv('COMPUTERNAME');
        case 0
            hostName = getenv('USER');
    end
    
    if ~isfield(opts,'hostName'), opts.hostName=hostName; end
    if ~isfield(opts,'paths'), opts.paths=struct; end
       
    switch hostName
        case 'electro'
            if ~isfield(opts.paths,'stem'), opts.paths.stem='/home/electro'; end
            if ~isfield(opts.paths,'nCORTEx_repo'), opts.paths.nCORTEx_repo = '/home/electro/Code_Repo/n-CORTEx'; end
            if ~isfield(opts.paths,'NECdrive_root'), opts.paths.NECdrive_cloud = '/home/electro/NEC_Drive'; end            
        case 'genoma'
            if ~isfield(opts.paths,'stem'), opts.paths.stem='/home/genoma'; end
            if ~isfield(opts.paths,'nCORTEx_repo'), opts.paths.nCORTEx_repo = '/home/genoma/Code_Repo/n-CORTEx'; end
            if ~isfield(opts.paths,'NECdrive_root'), opts.paths.NECdrive_cloud = '/home/genoma/NEC_Drive'; end
    end

    if ~isfield(opts.paths,'tempDir'), opts.paths.tempDir=fullfile(opts.paths.stem,'nCORTExTmp'); end
    if ~exist(opts.paths.tempDir,'dir'), mkdir(opts.paths.tempDir); end

    %% SPINVIEW PARAMS
    if ~isfield(opts,'spinParams'), opts.spinParams=struct; end
    if ~isfield(opts.spinParams,'saveDir'), opts.spinParams.saveDir=opts.paths.tempDir; end
    if ~isfield(opts.spinParams,'camSelect'), opts.spinParams.camSelect=0; end
    % pupilCam config
    if ~isfield(opts.spinParams,'pupilCam'), opts.spinParams.pupilCam=struct; end
    if ~isfield(opts.spinParams,'pupilSN'), opts.spinParams.pupilSN='21277600'; end
    if ~isfield(opts.spinParams.pupilCam,'TriggerMode'), opts.spinParams.pupilCam.TriggerMode='On'; end
    if ~isfield(opts.spinParams.pupilCam,'TriggerSource'), opts.spinParams.pupilCam.TriggerSource='Line2'; end
    if ~isfield(opts.spinParams.pupilCam,'TriggerActivation'), opts.spinParams.pupilCam.TriggerActivation='RisingEdge'; end
    if ~isfield(opts.spinParams.pupilCam,'DecimationHorizontal'), opts.spinParams.pupilCam.DecimationHorizontal=1; end
    if ~isfield(opts.spinParams.pupilCam, 'DecimationVertical'), opts.spinParams.pupilCam.DecimationHorizontal=1; end
    if ~isfield(opts.spinParams.pupilCam, 'ExposureMode'), opts.spinParams.pupilCam.ExposureMode='TriggerWidth'; end
    if ~isfield(opts.spinParams.pupilCam, 'GammaEnable'), opts.spinParams.pupilCam.GammaEnable='false'; end
    
    % if ~isfield(opts.spinParams,'pupilCv2'), opts.spinParams.pupilCv2=struct; end
    % if ~isfield(opts.spinParams.pupilCv2,'fps'), opts.spinParams.pupilCv2.fps=10; end
    % if ~isfield(opts.spinParams.pupilCv2,'frameSizeW'), opts.spinParams.pupilCv2.frameSizeW=640; end
    % if ~isfield(opts.spinParams.pupilCv2,'frameSizeH'), opts.spinParams.pupilCv2.frameSizeH=480; end
    % if ~isfield(opts.spinParams.pupilCam,''), opts.spinParams.pupilCam=; end
    % if ~isfield(opts.spinParams.pupilCam,''), opts.spinParams.pupilCam=; end
    % if ~isfield(opts.spinParams.pupilCam,''), opts.spinParams.pupilCam=; end
    % if ~isfield(opts.spinParams.pupilCam,''), opts.spinParams.pupilCam=; end
    
    % whiskCam config
    if ~isfield(opts.spinParams,'whiskCam'), opts.spinParams.whiskCam=struct; end
    if ~isfield(opts.spinParams,'whiskSN'), opts.spinParams.whiskSN='23248866'; end
    if ~isfield(opts.spinParams.whiskCam,'TriggerMode'), opts.spinParams.whiskCam.TriggerMode='On'; end
    if ~isfield(opts.spinParams.whiskCam,'TriggerSource'), opts.spinParams.whiskCam.TriggerSource='Line2'; end
    if ~isfield(opts.spinParams.whiskCam,'TriggerActivation'), opts.spinParams.whiskCam.TriggerActivation='RisingEdge'; end
    if ~isfield(opts.spinParams.whiskCam,'DecimationHorizontal'), opts.spinParams.whiskCam.DecimationHorizontal=2; end
    if ~isfield(opts.spinParams.whiskCam, 'DecimationVertical'), opts.spinParams.whiskCam.DecimationHorizontal=2; end
    if ~isfield(opts.spinParams.whiskCam, 'ExposureMode'), opts.spinParams.whiskCam.ExposureMode='TriggerWidth'; end
    if ~isfield(opts.spinParams.whiskCam, 'GammaEnable'), opts.spinParams.whiskCam.GammaEnable='false'; end
    % if ~isfield(opts.spinParams.whiskCam, 'PixelFormat'), opts.spinParams.whiskCam.PixelFormat='BGRa8'; end
    % if ~isfield(opts.spinParams.whiskCam, 'Width'), opts.spinParams.whiskCam.Width=500; end
    % if ~isfield(opts.spinParams.whiskCam, 'Height'), opts.spinParams.whiskCam.Height=400; end
    
    % if ~isfield(opts.spinParams,'whiskCv2'), opts.spinParams.whiskCv2=struct;
    % if ~isfield(opts.spinParams.whiskCv2,'fps'), opts.spinParams.whiskCv2.fps=50; end
    % if ~isfield(opts.spinParams.whiskCv2,'frameSizeW'), opts.spinParams.whiskCv2.frameSizeW=640; end
    % if ~isfield(opts.spinParams.whiskCv2,'frameSizeH'), opts.spinParams.whiskCv2.frameSizeH=480; end
    % if ~isfield(opts.spinParams.whiskCam,''), opts.spinParams.whiskCam=; end
    % if ~isfield(opts.spinParams.whiskCam,''), opts.spinParams.whiskCam=; end
    % if ~isfield(opts.spinParams.whiskCam,''), opts.spinParams.whiskCam=; end
    % if ~isfield(opts.spinParams.whiskCam,''), opts.spinParams.whiskCam=; end

    if ~isfield(opts,'validationParams'), opts.validationParams = struct; end
    if ~isfield(opts.validationParams, 'stdThreshold'), opts.validationParams.stdThreshold = 0.1; end % std allowance in Hz
    if ~isfield(opts.validationParams, 'meanThreshold'), opts.validationParams.meanThreshold = 1; end % mean deviation allowance in Hz

    % if ~isfield(opts,'dataStream'),opts.dataStream=struct; end 
    % if ~isfield(opts.dataStream,'Pupillometry'), opts.dataStream.Pupillometry=0; end
    % if ~isfield(opts.dataStream,'Neuropixels'), opts.dataStream.Neuropixels=0; end
    % if ~isfield(opts.dataStream,'Photometry'), opts.dataStream.Photometry=0; end
    % if ~isfield(opts.dataStream,'Piezo'), opts.dataStream.Piezo=0; end
    % 
    params = opts;
    % dsMask = params.dataStream;
    % dsMask.pth = params.paths.nCORTEx_repo;
    % save(fullfile(params.paths.nCORTEx_repo,'dsMask.mat'),'dsMask');
end