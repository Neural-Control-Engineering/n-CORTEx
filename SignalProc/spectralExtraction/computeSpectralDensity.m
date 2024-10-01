function [PSD, f, t] = computeSpectralDensity(cfg, dataFrame)
    % if isempty(cfg)
    %     method="pmtm";
    %     stride=10;
    %     fRange=[0,50];
    %     windowLen=400;
    %     Fs = 500;
    %     nfft = 2048;
    % else
    %     method = cfg.method;
    %     stride = cfg.stride;
    %     fRange = cfg.fRange;
    %     windowLen = cfg.windowLen;
    %     Fs = cfg.Fs;
    %     nfft = cfg.nfft;    
    %     chanRange = cfg.chanRange;
    % end
    try    method=cfg.method; catch method="pmtm"; end
    try    stride=cfg.stride; catch stride=10; end
    try    fRange=cfg.fRange; catch fRange=[0,50]; end
    try    windowLen=cfg.windowLen; catch windowLen=400; end
    try    Fs=cfg.Fs; catch Fs=500; end
    try    nfft=cfg.nfft; catch nfft=2048; end
    try    chanRange=cfg.chanRange; catch chanRange=[1:385]; end
    try eofGap = cfg.eofGap; catch eofGap=windowLen; end

    disp(cfg.method);
    if strcmp(method,"multispec")
        multiSpec = [];
            for i = 1:size(dataFrame, dim)
                switch dim
                    case 1
                        dataChan = dataFrame(i,:);
                    case 2
                        dataChan = dataFrame(:,i);
                end
                % [spec, f, t] = spectrogram(dataChan, hanning(windowSize), overlap, [], fs);
                [spec, f, t] = spectrogram(dataChan, (windowSize), overlap, [], fs);
                multiSpec = cat(3, multiSpec, spec);
            end
    elseif strcmp(method,"cwt")
        PSD = [];        
        % for i = 1:size(dataFrame,1)
        for i = 1:size(chanRange)
            chanSelect = chanRange(i);
            [Wvs, Freqs] = cwt(dataFrame(chanSelect,:),'morse',500,"TimeBandwidth",10);
            PSD = cat(3, PSD, Wvs);
            f = Freqs;
            t = [1:size(Wvs,2)]./Fs - 3.5;
        end
        PSD = permute(PSD, [3, 1, 2]);
    else       
        PSD = {};        
        F = {};
        T = {};
        parfor i = 1:(size(dataFrame,2)-eofGap) % for each 'time' point-
            disp(i);
            winData = dataFrame(:,i:i+windowLen);
            psdStride = [];                  
            for j=1:size(chanRange) % for each chan
                chanSelect = chanRange(j);
                winData_chan = winData(chanSelect,:);
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
                fCond = (f>fRange(1)) & (f<fRange(2));
                f = f(fCond==1);
                psd = psd(fCond==1);
                psdStride = [psdStride; psd']; 
                t = [1:size(dataFrame,2)-eofGap]./Fs - 3.5;
                % f_chans = [f_chans; f'];
                % t_chans = [t_chans; t'];
            end
            % PSD = cat(3, PSD, psdStride);
            PSD{i,1} = psdStride;    
            F{i,1} = f;
            T{i,1} = t;            
        end        
        % Stack PSD time cells
        PSD = cat(3, PSD{:});        
        f = F{1,1};
        t = T{1,1};
    end
end