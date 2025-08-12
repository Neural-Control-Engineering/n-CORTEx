function Ax = colorAx_green(Ax)
    try
        Ax.GridColor=[0.24,0.94,0.46];
        Ax.Color=[0,0,0];
        Ax.XColor=[0.24,0.94,0.46];
        Ax.YColor=[0.24,0.94,0.46];
    catch e
        switch class(Ax)
            case 'matlab.graphics.chart.primitive.Scatter'            
                Ax.Parent.GridColor=[0.24,0.94,0.46];
                Ax.Parent.Color=[0,0,0];
                Ax.Parent.XColor=[0.24,0.94,0.46];
                Ax.Parent.YColor=[0.24,0.94,0.46];
                try
                    Ax.Parent.ZColor = [0.24,0.94,0.46];
                catch
                end
        end
    end
        
end