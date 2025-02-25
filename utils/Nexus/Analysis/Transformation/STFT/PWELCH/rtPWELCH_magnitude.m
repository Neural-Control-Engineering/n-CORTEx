function nexTransform_rtPWELCH_magnitude(df_in, args)
    % low latency power spectral density estimates using the
    % multi-taper-method
    % leverages GPU array compatible code and parallel computing for a
    % pseudo-realtime processing of time series signals

    % output: df, f (vector), t (single)   

    % note: windowLen not used here but in the outer 'animate' function

    % CFG HEADER    
    chanRange_start = args.chanRange_start; % default = 1
    chanRange_end = args.chanRange_end; % default = 384    
    Fs = args.Fs; % default = 500

    frameNum = args.frameNum; % input sample step/number to return time point
    downSampleFactor=1;
    % load to cuda
    chanRange = [chanRange_start : chanRange_end];
    gpuBuffer = gpuArray(single(df_in(chanRange,:)'));
    gpuBuffer = downsample(gpuBuffer,downSampleFactor);        
    gpuBuffer = gpuBuffer';    
    S = {};
    F = {};    
    % for each channel
    parfor i = 1:size(gpuBuffer,1)
        x = gpuBuffer(i,:)';
        [psd, f] = (rtPWELCH(x, Fs));
        % take magnitude
        S{i} = abs(psd);
        F{i} = f;
    end    
    % figure; plot(gather(F{1}),log10(abs(gather(S{1}))))    
    SF = {S,F};    
    % parse outputs
    out.df = [SF{1,1}{:}]';
    out.ax.f = SF{1,2}{1};
    out.ax.t = frameNum / Fs;

end