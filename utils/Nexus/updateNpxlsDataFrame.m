function updateNpxlsDataFrame(nexon, shank, timeCourse, newDF)
    % apply dataFrame channels fo panel timecourses (using ptrIdx and
    % referencing probe data)
    nexon.console.NPXLS.shanks.(shankID).scope.(timeCourseID).dataFrame = newDF;   
    
end