function nexDraw_clearViolin(nexObj)
    V = nexObj.Figure.panel0.graphics.canvas;
    axList = V.axList;
    cla(axList(1));
    for i = 2:length(axList)
        ax_i = axList(i);
        delete(ax_i);        
    end
end