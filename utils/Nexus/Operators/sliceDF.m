function df_slice = sliceDF(df, ptr, axSel, sliceType)
    if nargin < 4
        % slice by a single dim pointer along selected axis
        idx = nex_buildSliceIndex(df, ptr, axSel, "single");
        df_slice = df(idx{:});
    else
         % slice along entire dim (sliceDim)
        idx = nex_buildSliceIndex(df, ptr, axSel, sliceType);        
        df_slice = df(idx{:});
    end
end