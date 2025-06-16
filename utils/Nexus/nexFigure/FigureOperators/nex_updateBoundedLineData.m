function nex_updateBoundedLineData(line, patch, data_ax, data, data_sem, color, alphaVal)    
    if ~isempty(color)
        color_hex = hex2rgb(color);
    else
        color_hex = [0,0,0];
    end
    if isempty(alphaVal)
        alphaVal = 0.5;
    end
    % Construct fill patch
    xFill = [data_ax, fliplr(data_ax)];
    yFill = [data + data_sem, fliplr(data - data_sem)];
    patch.Faces = [1:length(xFill)];
    patch.Vertices = [xFill',yFill'];
    patch.XData = xFill;
    patch.YData = yFill;
    patch.CData = color_hex;
    patch.FaceColor = color_hex;
    patch.FaceAlpha = alphaVal;

    line.XData = data_ax;
    line.YData = data;
    line.Color = color_hex;
end