function psd = slicePSD(df_psd, ptr)
    ptr_chans = ptr.chans;
    ptr_t = ptr.t;
    psd = df_psd(ptr_chans, :, ptr_t);
end