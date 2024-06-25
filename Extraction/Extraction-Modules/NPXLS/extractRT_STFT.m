function SFT = extractRT_STFT(dataBuffer)
    % tic
    Fs = 500;    
    % gpuBuffer = gpuArray(single(dataBuffer(:,384:767)));
    gpuBuffer = gpuArray(single(dataBuffer(:,384:444)));
    gpuBuffer = downsample(gpuBuffer,5);    
    % S = cell(384,1);
    gpuBuffer = gpuBuffer';
    buffLen = size(gpuBuffer,2);
    gpuBuffCell = mat2cell(gpuBuffer, ones(size(gpuBuffer, 1), 1), size(gpuBuffer, 2));
    [S, F, T] = cellfun(@(x) stft(x,Fs,"Window",hanning(buffLen/10),"OverlapLength",buffLen/10-1,"FFTLength",128,"FrequencyRange","onesided"), gpuBuffCell, "UniformOutput", false);
    SFT = {S,F,T};
    % imgHndl = imagesc([1:500]/Fs,F{1,1},10*log10(abs(S{1,1})));
    % toc
 
    % tic
    % s = stft(gpuBuffer(1,:),Fs);
    % toc    

    % parfor i = 1:size(gpuBuffer,2)        
    %     S{i} = stft(gpuBuffer(:,i),Fs)              
    % end
    
end