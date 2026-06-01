function dimsList = nexOp_listDfDims(DF)
    dimsList = convertCharsToStrings(fieldnames(DF.ax));
    dimsList = arrayfun(@(d) sprintf("ax--%s",d),dimsList,"UniformOutput",true);
end