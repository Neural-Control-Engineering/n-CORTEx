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
        f_cond = f > bRange(1) & f < bRange(2);
        bandPwr = psd(:,f_cond,:);
        bandPwr = mean(bandPwr,2);
        % iterate through channel-region map                        
        regAvgBuffer = [];
        Colors = [];
        Labels = [];
        figure        
        sh = stackedplot([]);
        sh.Title=sprintf("%s power %d-%d Hz",band,bRange(1),bRange(2));
        sh.Visible="off";
        sh.XData = t_stimAlgn';
        m=1;
        for i = 1:height(regMap)
            npxChan = regMap(i,:);
            channelNum = npxChan.channel{1};
            region = npxChan.region{1};
            % shortRegion = split(region,'-');
            % shortRegion = shortRegion{1};
            color = npxChan.color{1};
            if i > 1
                npxChanPrev = regMap(i-1,:);
                regionPrev = npxChanPrev.region{1};
                colorPrev = npxChanPrev.color{1};
                if ~strcmp(region, regionPrev) || (i == height(regMap))
                    regAvg = mean(regAvgBuffer,1);
                    sh.YData = [sh.YData, regAvg'];                
                    % sh.YData = [sh.YData, regAvgBuffer(end,:)'];
                    Colors = [Colors; sprintf("#%s",colorPrev)];
                    Labels = [Labels; string(regionPrev)];
                    m=m+1;
                    regAvgBuffer = [];                
                    regAvgBuffer = [regAvgBuffer; bandPwr(channelNum,:)];
                else
                    regAvgBuffer = [regAvgBuffer; bandPwr(channelNum,:)];
                end 
            else
                regAvgBuffer = [regAvgBuffer; bandPwr(channelNum,:)];                 
            end
        end

        for i = 1:size(Colors,1)
            sh.LineProperties(i).Color = Colors(i);
        end
        % sh.LineProperties(m).Color = sprintf("#%s",color);
        sh.DisplayLabels = Labels;
        sh.XLabel = "time (s)";
        sh.Visible="on";   
        set(gcf,'Position',[452,-573,560,1222]);
        set(gcf,'Color',[1.00,1.00,1.00]);
        saveas(gcf,sprintf("%s.png",band))
        saveas(gcf,sprintf("%s.fig",band))
    end
end