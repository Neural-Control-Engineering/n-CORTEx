function DF = grabDF(nexObj, dtsIdx)
    dfID = sprintf("%s--%s","chg",nexObj.dfID);
    DF.df = grabDataFrame(nexObj.nexon, sprintf("%s_df",dfID), dtsIdx);
    DF.ax.t = grabDataFrame(nexObj.nexon, sprintf("%s_t",dfID), dtsIdx);
    DF.ax.f = grabDataFrame(nexObj.nexon, sprintf("%s_f",dfID), dtsIdx);
    DF.ax.chans = grabDataFrame(nexObj.nexon, sprintf("%s_chans",dfID), dtsIdx);
end