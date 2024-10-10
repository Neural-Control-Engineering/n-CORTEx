function SFT = extractRT_STFT(streamCfg, dataBuffer)
    % tic
    % Fs = 500; 
    try    Fs=streamCfg.Fs; catch Fs=500; end
    try    chanRange=streamCfg.chanRange; catch chanRange=[1:384]; end
    try    downSampleFactor=streamCfg.downSampleFactor; catch downSampleFactor=1; end
    % chanRange = streamCfg.chanRange;
    % gpuBuffer = gpuArray(single(dataBuffer(:,384:767)));
    % gpuBuffer = gpuArray(single(dataBuffer(:,384:444)));
    gpuBuffer = gpuArray(single(dataBuffer(:,chanRange)));
    gpuBuffer = downsample(gpuBuffer,downSampleFactor);    
    % S = cell(384,1);
    gpuBuffer = gpuBuffer';
    buffLen = size(gpuBuffer,2);
    gpuBuffCell = mat2cell(gpuBuffer, ones(size(gpuBuffer, 1), 1), size(gpuBuffer, 2));
    % [S, F, T] = cellfun(@(x) stft(x,Fs,"Window",hanning(buffLen/10),"OverlapLength",floor(buffLen/10)-1,"FFTLength",128,"FrequencyRange","onesided"), gpuBuffCell, "UniformOutput", false);
    [S, F, T] = cellfun(@(x) stft(x,Fs,"Window",hanning(buffLen/10),"OverlapLength",floor(buffLen/10)-1,"FFTLength",2048,"FrequencyRange","onesided"), gpuBuffCell, "UniformOutput", false);
    SFT = {S,F,T};
    % imgHndl = imagesc([1:500]/Fs,F{1,1},10*log10(abs(S{1,1})));
    % toc
 
    % tic
    % s = stft(gpuBuffer(1,:),Fs);
    % toc    
    psd = gather(S{1});

    % parfor i = 1:size(gpuBuffer,2)        
    %     S{i} = stft(gpuBuffer(:,i),Fs)              
    % end
    
end