function plot_regionXpowerbands(regMap, bands, lfp)
    % stacked plot of canonical lfp band powers 
    % over time (colored by atlas)
    Fs = 500;
    % get spectrogram
    [psd, f, t] = microMultiSpec(lfp, Fs);
    % stim aligned time
    t_stimAlgn = t - 1710 / Fs;
    bandNames = fieldnames(bands);
    % iterate through bands
    for j = 1:length(bandNames)
        band = bandNames{j};
        bRange = bands.(band);
        bandPwr = psd(:,bRange(1):bRange(2),:);
        bandPwr = mean(bandPwr,2);
        % iterate through channel-region map
        figure
        hold on;
        for i = 1:height(regMap)
            npxChan = regMap(i,:);
            channelNum = npxChan.channel{1};
            region = npxChan.region{1};
            shortRegion = split(region,'-');
            shortRegion = shortRegion{1};
            color = npxChan.color{1};
            
            chanTC = bandPwr(channelNum,:);
            plot(chanTC, 'Color',sprintf("#%s",color))
        end
        hold off;
    end
end