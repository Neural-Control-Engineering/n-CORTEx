function DF = nexOp_profileDF(DF, axSel)
    df_slice = nexOp_sliceAndCollapse(DF, axSel);
    DF.model.profile = DF.model.basis(df_slice, DF.model.coeff);
end