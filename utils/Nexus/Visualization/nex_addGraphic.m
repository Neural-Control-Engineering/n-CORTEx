function nex_addGraphic(nexObj, axis, graphic, ID_graphic)
    nexObj.Figure.panel1.tiles.graphics.(ID_graphic) = graphic;
    graphic.Parent=axis;
    graphic.Visible="on";    
    colorAx_green(axis);
end