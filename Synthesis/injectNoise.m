function sig_noise = injectNoise(sig)
    noiseCap = (rand() * 0.45);    
    %% Generate noise
    whiteNoise = rand(1,size(sig,2));
    % bandPass
    band = zeros(1, size(sig,2));
    f_cuts = floor(rand(1,2) * (size(sig,2)-1))+1;
    band(:,min(f_cuts):max(f_cuts)) = noiseCap;
    fft_white = fft(whiteNoise);
    % figure; plot(abs(fft_white))
    % figure; plot(whiteNoise)
    % fft_color = fft_white .* (1 ./ (f.^coloringExp));
    fft_color = fft_white .* band;
    % figure; plot(abs(fft_color));
    coloredNoise = ifft(fft_color);
    % figure; plot(abs(coloredNoise))
    %% Convolve Signal with noise (inject)
    coloredNoise = abs(coloredNoise) - mean(abs(coloredNoise));
    % noiseNorm = (coloredNoise - mean(coloredNoise)) / (max(coloredNoise) - min(coloredNoise));    
    % figure; plot(noiseNorm)
    noise_sc = (coloredNoise * (max(sig)-min(sig) * 0.1));
    sig_noise = sig +  noise_sc;
    % figure; plot(sig_noise - mean(sig_noise));
    % hold on
    % plot(sig - mean(sig));
    % plot(noise_sc - mean(noise_sc));
end