function loadLFPTimeCourse(nexon, shank, timeCourse)
    % timeCourse.dataFrame = timeCourse.UserData.lfp;
    timeCourse.dataFrame = grabDataFrame(nexon,timeCourse.dfID,[]);
    updateTimeCourse(shank, timeCourse,[]);
end