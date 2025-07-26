function expIO_rtSpec(nexon, DF_tgt, DF_src, Y, fid_index, foldDir)
    % write data sample to batch; store label in the index
    % separate each channel
    n_chan = size(DF_tgt.df,1);
    n_time = size(DF_tgt.df,3);
    for i=1:n_chan
        for j=1:n_time
            % gather
            spec = DF_tgt.df(i,:,j);
            f_spec = DF_tgt.ax.f;
            psd_specs = 10*spec2psd(f_spec, spec);
            plot(psd_specs)
            figure; plot(psd_specs)
            hold on
            
            f_psd = DF_src.ax.f;
            fCond = (f_psd>=f_spec)&(f_psd<=f_spec);
            f_psd = f_psd(fCond);
            psd = DF_src.df(i,:,j);
            psd = psd(fCond)
            psd_specs = 10*spec2psd(f_spec, spec);
            % psd_specs = spec2psd(f_spec, spec);
            % figure; plot(psd); hold on; plot(psd_specs)
            figure; plot(psd_specs);
            figure; plot(psd)
            % write sample
            % write to index
        end
    end
end