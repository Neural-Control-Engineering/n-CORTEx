function generateCols_SLRTsignal(SLRT, signalTags)
    signalTags = ["stimTrace_raw","stimTrace_lowess_span2"];
    preBuffLen = 3.5;
    origPreBuff = 1;
    preBuffAppend = preBuffLen-origPreBuff;
    fs_SLRT = 1000;
    for i = 1:length(signalTags)
        signalTag = signalTags(i);
        slrtSignal = SLRT.(signalTag);
        [preBuffSignal, t] = cellfun(@(x) imputePreBuffMean(x, preBuffLen, origPreBuffLen, fs), slrtSignal, "UniformOutput", false);
        newSignalTitle = sprintf("onset_aligned_%s",signalTag);
        newSignalTimeTitle = sprintf("%s_time",newSignalTitle);
        SLRT.(newSignalTitle) = preBuffSignal;
        SLRT.(newSignalTimeTitle) = t;
        % JOLT PEAK ALIGNMENT (HARD-CODED, OPTIONAL)
        % [peakVal, onsetVal, minVal, idxPeak, idxOnset, idxMin] = cellfun(@(x) evaluatePeak_jolt(t,stimSmooth);
        t_peakAligned = cellfun(@(x,t) alignTimeToSignalPeak(x,t), preBuffSignal,t,"UniformOutput",false);
        peakAlgnSignalTitle = sprintf("peak_aligned_%s", signalTag);
        peakAlgnSignalTimeTitle = sprintf("%s_time",peakAlgnSignalTitle);
        SLRT.(peakAlgnSignalTimeTitle) = t_peakAligned;
    end
end