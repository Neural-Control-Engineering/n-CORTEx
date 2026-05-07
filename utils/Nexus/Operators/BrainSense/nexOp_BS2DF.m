function DF = nexOp_BS2DF(R, rID)
    DF = R;
    switch rID
        case 'event'
            DF.lfp_df=R.FFT;
            DF.lfp_f={R.f'};
            % DF.ptr = nexInit_axisPointer(DF.lfp_df, DF.lfp_f);
            DF=rmfield(DF,'FFT');
            DF=rmfield(DF,'f');
        case 'montage'
            DF.df=R.FFT;
            DF.ax.f=R.f';
            DF=rmfield(DF,'FFT');
            DF=rmfield(DF,'f');
        case 'brainSense'            
            DF.lfp_df=R.LFP_bs.LFP';
            DF.lfp_t=(R.LFP_bs.TicksInMs')./1000';
            DF.lfp_t=DF.lfp_t-min(DF.lfp_t);
            % DF.ptr = nexInit_axisPointer(DF.lfp_df, DF.lfp_f);
            DF=rmfield(DF,'LFP_bs');
            % DF=rmfield(DF,'f');
    end
end