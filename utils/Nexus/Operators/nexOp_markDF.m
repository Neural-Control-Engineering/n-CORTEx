function nexOp_markDF(DF, axSel, mkrFcn, color)
    % use corner frequencies to mark DF
    DF.mkr.(axSel).(mkrFcnID).value = mkrFcn(ax_slice, df_slice);
    DF.mkr.(axSel).(mkrFcnID).color = color;
end