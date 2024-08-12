function sig = composeSpecs(f, sp)
    % compose spectral parameters (fooof-fitting) into a signal (e.g. for
    % plotting)
    fract = sp.aperiodic_params;
    peaks = sp.peak_params;
    % f = [1:size(sp.power_spectrum,2)];     
    fract_fit = log10(1./(f.^fract(2)));
    sig = fract_fit;
    for i = 1:size(peaks,1)
        mu = peaks(i,1); % CF
        sigma = peaks(i,3); % BW
        A = peaks(i,2); % PW
        G = A * exp(-(f - mu).^2 / (2 * sigma^2));
        % add each peak
        sig = sig + (G);
    end
    % add bias
    sig = sig + fract(1);
    
end