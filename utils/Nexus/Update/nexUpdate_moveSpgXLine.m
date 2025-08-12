function nexUpdate_moveSpgXLine(nexon, nexObj, xIdx)
    % figureChildren = nexObjFigure.Parent.Children;
    figureChildren = nexObj.spgFigure.panel1.tiles.Axes.spectroGram.Parent.Children;
    % xLineObj.Value = xIdx;
    for i = 1:length(figureChildren)
        figureChild = figureChildren(i);
        if class(figureChild) == "matlab.graphics.chart.decoration.ConstantLine"
            figureChild.Value = xIdx;
            return
        end
    end

    % if not returned by now create a new xline
    xline(nexObj.spgFigure.panel1.tiles.Axes.spectroGram.Parent,xIdx,"Color",nexon.settings.Colors.cyberGreen);

end