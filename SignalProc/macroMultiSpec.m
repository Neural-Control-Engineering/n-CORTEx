function [psd, f, t] = macroMultiSpec(lfp, Fs)
    [psd, f, t] = multiSpectrogram(lfp, Fs, 160, 159, 1);
    psd = 10*log10(abs(psd));
    psd = permute(psd(:,:,1:384),[3,1,2]);
end