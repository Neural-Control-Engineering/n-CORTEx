function fh = plotPSDSweep(params, signalIn, stepSize, fs, fftLen)

    % defs 
    fftLen = 10000;
    overlap = 1200;
    windowSize = 2000;
    
    % filter to range of interest
    sig_filt = linearPhaseBP(params, signalIn, fs, 40, 100);

    % Sweep over channel groups
    height = size(sig_filt,1);
    for i = 1:height
        if i < (height - stepSize)
            strt = stepSize*(i-1)+1;
            stop = stepSize*(i)+1;
            % take average
            sigAvg_filt = mean(sig_filt(strt:stop,:),1);
            % compute spectrogram
            % [~, f, t, specGram] = spectrogram(sig_filt(i:i+stepSize), window, overlap, fftLen, fs);
            % Compute the spectrogram
            [S, F, T] = spectrogram(sigAvg_filt, windowSize, overlap, [], fs);
            S_mag = 10*log10(abs(S));
            fh = figure;
            imagesc(T, F(F<50), S_mag(F<50,:));
            xlabel("time (s)");
            ylabel("freq (Hz)");
            colorbar
            title(sprintf("Channels %d : %d",strt, stop));
            fh2 = figure;
            surf(T, F(F<50), S_mag(F<50,:));
            view(100,30)
            xlabel("time (s)");
            ylabel("freq (Hz)");
            zlabel("power (10*log10(|z|)")
            title(sprintf("Channels %d : %d",strt, stop));
            % convert magnitude to power
            % [psd, freq] = pwelch(10*log10(abs(S)), windowSize, overlap, fftLen, fs);
            % 
            % fh = figure;
            % plolt(psd, freq);
        end
    end
end