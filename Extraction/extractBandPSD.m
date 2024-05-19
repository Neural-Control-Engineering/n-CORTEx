function PSD = extractBandPSD(lfp, bands)
    bandNames = fieldnames(bands);        
    lfp = downsample(lfp,5);
    fs = 500;
    % figure; t = tiledlayout(ceil(384/30),2);
    PSD = cell(384,5);
    parfor i = 1:size(lfp,2)
        % nexttile(t);
        chanLfp = double(lfp(:,i));
        N = 2000;
        [fT] = fft(chanLfp,N,1);        
        f = fs/N * [1:N/2 + 1];
        
        psd = abs(fT/N).^2;
        psd = psd(1:N/2+1) / fs;        
        psd = 10*log10(psd);
    
        % figure;
        % plot(f(1:200),10*log10(psd(1:200)));
        % plot(f,10*log10(psd));
        % xlabel("Frequency (Hz)")
        % title(sprintf("chan-%d",i))
        % figure; plot(10*log10(abs(fT(1:N/2+1))));
        % set(gcf,"Position",[100,188,900,1530])

        % Temporary variable to hold PSD values for the current channel
        tempPSD = zeros(1, length(bandNames));
    
        for j = 1:length(bandNames)
            band = bandNames{j};
            bRange = bands.(band);
            fCond = find(f > bRange(1) & f < bRange(2));
            tempPSD(j) = mean(psd(fCond));
        end
    
        % Assign the temporary PSD values to the main PSD cell array
        PSD(i, :) = num2cell(tempPSD);
    end
end