function df_cf = psdIO_estimateCornerFrequencies(DF)

    axSel = 'f';
    % f_psd = DF.ax.f;
    [df_psd, ax_slice] = nexOp_sliceAndCollapse(DF, axSel);
    f_psd = ax_slice.f;
    % invoke subroutine
    df_cf = psdIO_readCornerFrequencies(f_psd, df_psd);
end