function PSD, f, t= computeSpectralDensity(cfg, data)
    method = cfg.method;
    stride = cfg.stride;
    fRange = cfg.fRange;
    windowLen = cfg.windowLen;
    Fs = cfg.Fs;
    nfft = cfg.nfft;    
    if strcmp(method,"multispec")
        multiSpec = [];
            for i = 1:size(dataStream, dim)
                switch dim
                    case 1
                        dataChan = dataStream(i,:);
                    case 2
                        dataChan = dataStream(:,i);
                end
                % [spec, f, t] = spectrogram(dataChan, hanning(windowSize), overlap, [], fs);
                [spec, f, t] = spectrogram(dataChan, (windowSize), overlap, [], fs);
                multiSpec = cat(3, multiSpec, spec);
            end
    end
    switch method
        case "pmtm"
            psdFcn = @(~,~)  [PMT, f_pmt]  = pmtm(data', 10, nfft, Fs ,'Tapers','sine');
        case "pwelch"
            psdFcn = @(~,~)pwelch(data,window, floor(win/2), nfft, Fs);        
    end
    PSD = {};        
    parfor i = 1:stride:(size(data,2)-windowLen) % for each 'time' point-
        disp(i);
        winData = data(:,i:i+windowLen);
        psdStride = [];
        for j=1:size(data,1) % for each chan
            winData_chan = winData(j,:);
            switch method
                case "pmtm"
                    [psd, f] = pmtm(winData_chan,10,nfft/2,Fs,'Tapers','sine');                    
                   %  fCond = (f>fRange(1))&(f<fRange(2));
                   % figure;  plot(f(fCond==1),log10(abs(psd(fCond==1))))
                case "pwelch"
                    [psd, f] = pwelch(winData_chan, hanning(windowLen), floor(windowLen/2), nfft, Fs);
                    % fCond = (f>fRange(1))&(f<fRange(2));
                    % figure;  plot(f(fCond==1),log10(abs(psd(fCond==1))))
                case "fft"
                    [psd] = fft(winData_chan',nfft);
                    % figure;  plot(log10(abs(psd)))                    
            end
            fCond = (f>fRange(1))&(f<fRange(2));
            f = f(fCond==1);
            psd = psd(fCond==1);
            psdStride = [psdStride; psd'];
        end
        % PSD = cat(3, PSD, psdStride);
        PSD{i,1} = psdStride;        
    end    
    % Stack PSD time cells
    PSD = cat(3, PSD{:});
end