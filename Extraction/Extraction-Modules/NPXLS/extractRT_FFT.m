function SF = extractRT_FFT(streamCfg, dataBuffer)    
    % catch parameters
    try    Fs=streamCfg.Fs; catch Fs=500; end
    try    chanRange=streamCfg.chanRange; catch chanRange=[1:384]; end
    try    downSampleFactor=streamCfg.downSampleFactor; catch downSampleFactor=1; end    
    % load to cuda
    gpuBuffer = gpuArray(single(dataBuffer(:,chanRange)));
    gpuBuffer = downsample(gpuBuffer,downSampleFactor);        
    gpuBuffer = gpuBuffer';    
    S = {};
    F = {};    
    parfor i = 1:size(gpuBuffer,1)
        x = gpuBuffer(i,:)';
        [S{i}, F{i}] = (fPMTM(x, Fs, 1));
    end    
    % figure; plot(gather(F{1}),log10(abs(gather(S{1}))))    
    SF = {S,F};    
end