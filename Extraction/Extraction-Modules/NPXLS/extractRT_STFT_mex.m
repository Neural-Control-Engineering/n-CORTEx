function extractRT_STFT_mex(dataBuffer)

    coder.extrinsic('gpuArray');

    Fs = 500;    
    gpuBuffer = gpuArray(double(dataBuffer(:,384:767)));
    % gpuBuffer = downsample(gpuBuffer,5);    
    gpuBuffer = decimate(gpuBuffer,5);       
    S = cell(384,1);    
    % tic
    parfor i = 1:384
        S{i} = stft(gpuBuffer(:,i),Fs)              
    end
    % toc 
end