function fooofPrediction = extractRT_fooof(rtSpec, psd)
    % resampleDataFrame resamples the input PSD matrix to have nPoints columns.
    %
    % Inputs:
    %   rtSpec - fooof predicting model (neural network)
    %   psd  - spectral data (numChannels x psdPoints)
    %
    % Outputs:
    %   fooof predictions

    % resample to appropriate size
    psd = resampleDataFrame(psd);
    % normalize and concatenate offset value
    % Normalize PSD: (psd - mean) / (std + epsilon)
    meanPSD = mean(psd, 2);  % Compute mean across each row (channel)
    stdPSD = std(psd, 0, 2); % Compute std across each row (channel)
    epsilon = 1e-7;          % Small value to avoid division by zero
    
    % Normalize each channel's PSD
    psd_z = (psd - meanPSD) ./ (stdPSD + epsilon);
    
    % Concatenate the offset (mean) as an extra column
    psd_z = [psd_z, meanPSD];
    
    % Reshape the PSD matrix to have dimensions numChannels x 1 x 196
    [numChannels, ~] = size(psd_z);
    psdTest = reshape(psd_z, [numChannels, 1, 196]);
    
    % Convert the PSD matrix to a Python tensor using py.torch
    psdNumpy = py.numpy.array(psdTest);
    psdTensor = py.torch.tensor(psdNumpy, pyargs('dtype', py.torch.float32));    
    
    % Move the tensor to GPU (CUDA) if available
    % pTen = psdTensor.unsqueeze(int32(-1)); % Add batch dimension
    % pTen = pTen.unsqueeze(int32(-1));      % Add additional dimension for channels
    
    % Run the forward pass through the FOOOF predicting model (assuming rtSpec is the model)
    % tic
    fooofPredictionTensor = rtSpec.fit(psdTensor.cuda());
    % toc
    fooofPredictionNumpy = fooofPredictionTensor.cpu().detach().numpy();    
    % Convert the NumPy array back to a MATLAB array
    fooofPrediction = double(fooofPredictionNumpy);    
end