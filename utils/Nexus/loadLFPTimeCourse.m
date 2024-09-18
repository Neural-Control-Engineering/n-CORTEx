function loadLFPTimeCourse(nexon, shank, timeCourse)
    timeCourse.dataFrame = timeCourse.UserData.lfp;
    updateTimeCourse(shank, timeCourse);
end