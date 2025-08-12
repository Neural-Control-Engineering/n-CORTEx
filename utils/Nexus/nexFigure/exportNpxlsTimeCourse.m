function exportNpxlsTimeCourse(nexon,shank,timeCourse)
    tcCopy = copyobj()
    tcFigure = figure;
    tcCopy = copyobj(timeCourse.tcFigure.panel1.tiles.t,tcFigure);
    set(tcFigure,"Color",[0,0,0])    
end