function CT = buildColorMap(C)   
    % default C
    % C = [0,0,0;0.35,0.39,0.35,;0.38,1,0.53]
    
    % Define the number of color stops based on the size of C
    num_stops = size(C, 1);

    % Create 16 equally spaced color stops
    N = 256;
    x0 = linspace(0, 1, num_stops);
    xf = linspace(0, 1, N);

    % Interpolate the colormap
    CT = interp1(x0, C, xf, 'pchip');

end