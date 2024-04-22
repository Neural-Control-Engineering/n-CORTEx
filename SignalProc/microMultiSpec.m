function [psd, f, t] = microMultiSpec(lfp, Fs)
    [psd, f, t] = multiSpectrogram(lfp, Fs, 80, 79, 1);
    psd = 10*log10(abs(psd));
    psd = permute(psd(:,:,1:384),[3,1,2]);
end