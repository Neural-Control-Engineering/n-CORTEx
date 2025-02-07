function dataFrames = compileDataFrames(nexon, dfID)
    dataFrames = {};
    for i = 1:length(dfID)
        dfID_i = dfID(i);
        df = grabDataFrame(nexon, dfID_i,[]);
        dataFrames = [dataFrames; df'];
    end
end