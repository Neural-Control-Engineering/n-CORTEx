function applyMethod(nexon, shank, timeCourse)
    % run analysis method on neuropixels dataframe (generalizable later)
    % load output onto neuropixels timecourse and update
    methodCfg = timeCourse.UserData.methodCfg;
    try
        args = methodCfg.Panel.entryParams;
    catch e
        disp(getReport(e));
        args = methodCfg.entryParams;
    end
    disp(args);
    df_in = timeCourse.dataFrame;
    df_out = methodCfg.UserData.methodFcn(df_in, args);
    timeCourse.dataFrame = df_out;
    updateTimeCourse(shank, timeCourse,[]);
    disp("extraction complete")
end