function [df_slice, ax_slice] = nexOp_sliceDF(DF, axSels, axVals)
    [idx_slice, ax_slice] = nexOp_buildSliceIndex(DF.ax, DF.ptr, axSels, axVals);
    % Pad to ndims(df): ptr may have fewer fields than df dimensions (e.g. a
    % UMAP DF where only 'latent' is in ptr but df is 1×n_latents — a single
    % ':' would linearise the array).  Extra colons are no-ops on real dims.
    nDims = ndims(DF.df);
    while numel(idx_slice) < nDims, idx_slice{end+1} = ':'; end
    df_slice = DF.df(idx_slice{:});
    % ax_slice = axVals
end