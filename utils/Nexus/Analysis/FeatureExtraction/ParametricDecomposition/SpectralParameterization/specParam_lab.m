function specParam_lab()

    fRange_start = 3;
    fRange_end = 70;

    df_in = nexObj_fitScp.DF_postOp.df;
    f = nexObj_fitScp.DF_postOp.ax.f;
    % figure; loglog(df_in)
    % frequency range
    fCond = (f>=fRange_start)&(f<=fRange_end);
    df_in = df_in(fCond);
    f = f(fCond);

    [specs, scores] = specParam_df(f,df_in);
    % plot result
    psd_spec = spec2psd(f,specs{1,1},'fixed','gaussian');
    % psd_spec = spec2psd(f,specs{1,1},'fixed','doublexp');
    figure; plot(f, 10*psd_spec);
    hold on
    plot(f, df_in);

    %% SMOOTHING
    df_in = nexObj_fitScp.DF_postOp.df;
    df_smooth = lowess(df_in', 0.1);

end