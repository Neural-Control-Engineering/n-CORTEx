function nex_clearGraphics(graph)
    graphType = class(graph);
    switch graphType
        case "matlab.graphics.chart.primitive.Line"
            graph.XData=[];
            graph.YData=[];
        case "matlab.graphics.primitive.Patch"
            graph.Faces=[];
            graph.Vertices=[];
            graph.XData=[];
            graph.YData=[];            
    end
       
end