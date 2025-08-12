function [signal_impute, t] = imputePreBuffMean(signal, preBuffLen, origPreBuffLen, fs)
    if isnan(signal)
        signal_impute=nan;
        t=nan;
    elseif isempty(signal)         
        signal_impute=[];
        t=[];        
    else
        sampleLen_preBuff = preBuffLen * fs;
        imputeBuff = mean(signal(1:sampleLen_preBuff));
        newSigLen = ((preBuffLen) * fs) + size(signal,1);
        appendBuffLen = (preBuffLen - origPreBuffLen) * fs;
        imputeBuff = imputeBuff * ones([appendBuffLen,1]);
        signal_impute = [imputeBuff; signal];
        t = ([1:size(signal_impute,1)]' - preBuffLen*fs) ./ fs;
    end
end