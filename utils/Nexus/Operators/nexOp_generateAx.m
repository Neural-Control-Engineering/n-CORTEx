function ax = nexOp_generateAx(DF)
    dfSize = size(DF.df);
    for i = 1:length(dfSize)
        sz = dfSize(i);
        axID = sprintf("x%d",i);
        ax.(axID)=[1:sz];
    end
end