function nexVisualization_smoother(nexObj)
    nexObj.Figure.panel0.tiles.graphics.canvas_psd.YData = nexObj.DF.df;
    nexObj.Figure.panel0.tiles.graphics.canvas_smooth.YData = nexObj.DF_postOp.df;
end