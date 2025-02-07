function spg = grabSpectrogram(nexon, spgID)
    spg.dataFrame = grabDataFrame(nexon, sprintf("PSD_%s",spgID),[]);
    spg.dfID = sprintf("PSD_%s",spgID);
    spg.t = grabDataFrame(nexon, sprintf("t_%s",spgID),[]);
    spg.f = grabDataFrame(nexon, sprintf("f_%s",spgID),[]);
end