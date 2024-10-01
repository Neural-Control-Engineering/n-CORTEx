function loadLFPTimeCourse(nexon, shank, timeCourse)
    % timeCourse.dataFrame = timeCourse.UserData.lfp;
    timeCourse.dataFrame = grabDataFrame(nexon,"lfp");
    updateTimeCourse(shank, timeCourse,[]);
end