function [signal_resamp, t] = alignAx(signal, sig_fs, ref_fs, dim)
    R_samp = ref_fs / sig_fs;
    signal_resamp = resampleSignal(signal, R_samp);
    t = [1:1:size(signal_resamp,dim)]./ref_fs;
    
end