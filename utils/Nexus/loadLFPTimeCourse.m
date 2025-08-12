function loadLFPTimeCourse(nexon, shank, timeCourse)
    % timeCourse.dataFrame = timeCourse.UserData.lfp;
    timeCourse.dataFrame = grabDataFrame(nexon,timeCourse.dfID,[]);
    timeCourse.DF.df = grabDataFrame(nexon,timeCourse.dfID,[]);
    updateTimeCourse(shank, timeCourse,[]);
end