function Ax = plotFooofContours(Ax, f, fooofPredictions)
    % compose fooof channels into psd signals
    tic
    contours = composeFooofPreds(fooofPredictions, f, 8, 195);
    toc
    % draw contours onto surf ax
    % Number of channels and frequency points    
    nChannels = size(contours, 1);
    nPoints = length(f);
    
    % Create a grid of X (channel indices) and Y (frequency values)
    [X, Y] = meshgrid(1:nChannels, f);

    % Plot using surf, but customize it to show only the lines (edges)
    surf(Ax, X', Y', contours, 'EdgeColor', 'interp', 'FaceColor', 'none', 'LineWidth', 0.8);

    % Set labels for the axes
    xlabel(Ax, 'Channel Index');
    ylabel(Ax, 'Frequency (Hz)');
    zlabel(Ax, 'PSD Value');

    % Optional: Set grid, view angle, etc.
    grid(Ax, 'on');
    view(Ax, [120 30]);  % Adjust the 3D view angle

    % % Create the line plot of the contours in 3D space
    % figure; 
    % hold(Ax, 'on');  % Hold on to plot multiple lines on the same Axes
    % 
    % % Number of channels
    % nChannels = size(contours, 1);
    % 
    % % Loop over each channel and plot it as a line in 3D space
    % for i = 1:nChannels
    %     % Plot3: X = channel index (i), Y = frequency (f), Z = PSD (contours)
    %     plot3(Ax, ones(size(f)) * i, f, contours(i, :), 'LineWidth', 1.5,"Color",[0,0,0]);
    % end
    % 
    % % Set labels for the axes
    % xlabel(Ax, 'Channel Index');
    % ylabel(Ax, 'Frequency (Hz)');
    % zlabel(Ax, 'PSD Value');
    % 
    % % Optional: Set grid, view angle, etc.
    % grid(Ax, 'on');
    % view(Ax, [120 30]);  % Adjust the 3D view angle
    % 
    % hold(Ax, 'off');
    
end