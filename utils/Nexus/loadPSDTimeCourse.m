function loadPSDTimeCourse(nexon, shank, timeCourse)
    bandSel = shank.config.entryParams.bandSel;
    b = timeCourse.UserData.b;
    bandIdx = find(strcmp(b,bandSel));
    PSD_bands = timeCourse.UserData.PSD_bands;
    dataFrame = squeeze(PSD_bands(:,:,bandIdx));
    timeCourse.dataFrame = dataFrame;    
    updateTimeCourse(shank, timeCourse,[]);
end