function CT = buildColorMap(C0, C1)
    % Define the start and end colors
    start_color = [0, 0, 0];
    end_color = [0.31, 0.94, 0.46];
    
    % Create 16 equally spaced color stops
    num_stops = 16;
    stops = linspace(0, 1, num_stops);
    
    % Interpolate the RGB values for each stop
    interp_colors = zeros(num_stops, 3);
    for i = 1:num_stops
        interp_colors(i, :) = start_color + (end_color - start_color) * stops(i);
    end
    
    % Display the interpolated colors
    disp(interp_colors);
    
    % Create CT0 colormap
    CT0 = interp_colors;

    N = 256;
    x0 = [0 0.008889 0.03556 0.08 0.1422 0.2222 0.32 0.4356 0.5644 0.68 0.7778 0.8578 0.92 0.9644 0.9911 1];
    xf = linspace(0,1,N);
    CT = interp1(x0,CT0,xf,'pchip');
end