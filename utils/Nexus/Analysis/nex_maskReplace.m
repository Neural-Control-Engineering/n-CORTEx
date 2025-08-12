function df_maskRep = nex_maskReplace(df, repVal, mask)
    df_maskRep = (df);
    df_maskRep(mask) = repVal;
end