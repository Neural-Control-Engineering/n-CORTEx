function cfg = configurePsd()
    cfg = struct;
    cfg.method="fft";
    cfg.stride=1;
    cfg.fRange=[0,50];
    cfg.windowLen=200;
    cfg.Fs=500;
    cfg.nfft=2048;
    cfg.chanRange=[1:384];
    % try    method=cfg.method; catch cfg.method="fft"; end
    % try    stride=cfg.stride; catch stride=1; end
    % try    fRange=cfg.fRange; catch fRange=[0,50]; end
    % try    windowLen=cfg.windowLen; catch windowLen=200; end
    % try    Fs=cfg.Fs; catch Fs=500; end
    % try    nfft=cfg.nfft; catch nfft=2048; end
    % try    chanRange=cfg.chanRange; catch chanRange=[1:385]; end
    % try eofGap = cfg.eofGap; catch eofGap=windowLen; end
end