function DF = nex_grabDF(nexon, DFID,dtsIdx)
    dtsCols = nexon.console.BASE.DTS.Properties.VariableNames;
    DFColIdxs = find(contains(dtsCols,DFID));
    for i=DFColIdxs
        dtsCol = dtsCols{i};
        dtsVal = grabDataFrame(nexon, dtsCol,dtsIdx);
        suffix = split(dtsCol,"_");
        suffix = string(suffix{end});
        if strcmp(suffix,"df")
            DF.(suffix) = dtsVal;
        else
            DF.ax.(suffix) = dtsVal;
        end
    end
end