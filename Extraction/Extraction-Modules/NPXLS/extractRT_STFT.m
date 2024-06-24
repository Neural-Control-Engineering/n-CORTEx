function [S, F, T] = extractRT_STFT(dataBuffer)
    tic
    Fs = 500;    
    % gpuBuffer = gpuArray(single(dataBuffer(:,384:767)));
    gpuBuffer = gpuArray(single(dataBuffer(:,384:404)));
    gpuBuffer = downsample(gpuBuffer,5);    
    % S = cell(384,1);
    gpuBuffer = gpuBuffer';
    buffLen = size(gpuBuffer,2);
    gpuBuffCell = mat2cell(gpuBuffer, ones(size(gpuBuffer, 1), 1), size(gpuBuffer, 2));
    [S, F, T] = cellfun(@(x) stft(x,Fs,"Window",hanning(100),"OverlapLength",99), gpuBuffCell, "UniformOutput", false);
    % imgHndl = imagesc([1:500]/Fs,F{1,1},10*log10(abs(S{1,1})));
    toc
 
    % tic
    % s = stft(gpuBuffer(1,:),Fs);
    % toc    

    % parfor i = 1:size(gpuBuffer,2)        
    %     S{i} = stft(gpuBuffer(:,i),Fs)              
    % end
    
end