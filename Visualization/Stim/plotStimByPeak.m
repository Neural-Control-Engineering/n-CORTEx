function plotStimByPeak(stimTraces, Fs, preBuff, postBuff, color_single, color_mean)
    numTraces = size(stimTraces,1);
    figure;
    stimTraceMean = [];    
    for i = 1:numTraces
        stimTrace = stimTraces(i,:);
        preBias = mean(stimTrace(1:100)); % average of first 100 samples
        stimTrace = [ones(1,preBuff)*preBias, stimTrace, ones(1,postBuff)*mean(stimTrace)] - preBias;
        idx_peak = find(stimTrace==max(stimTrace));        
        stimTrace = stimTrace(idx_peak-preBuff:idx_peak+postBuff);        
        plot([1:length(stimTrace)]./Fs,stimTrace,"Color",color_single)
        xline(preBuff/Fs)
        stimTraceMean = [stimTraceMean; stimTrace];
        hold on
    end
    plot([1:length(stimTrace)]./Fs,mean(stimTraceMean,1),"Color",color_mean)
    hold off
end