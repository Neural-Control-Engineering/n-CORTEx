function [df_slice, ax_slice] = nexOp_sliceDF(DF, axSels, axVals)
    [idx_slice, ax_slice] = nexOp_buildSliceIndex(DF.ax, DF.ptr, axSels, axVals);
    df_slice = DF.df(idx_slice{:});
    % ax_slice = axVals
end