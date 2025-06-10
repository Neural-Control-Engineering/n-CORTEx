function [lineHandle, fillHandle] = plotWithSEM(ax, x, y, sem_y, color, alphaVal)
    % plotWithSEM Plot mean with SEM shading on specified axes.
    %
    %   [lineHandle, fillHandle] = plotWithSEM(ax, x, y, sem_y)
    %   plots the data 'y' with shaded standard error 'sem_y' on the axes 'ax'.
    %   If ax is empty, the plot is drawn on an invisible temporary axes.
    %
    %   Additional name-value pairs:
    %     - 'Color' : Line and shading color (default: [0 0 1])
    %     - 'FaceAlpha' : Transparency of SEM fill (default: 0.3)

    % arguments
    %     ax matlab.graphics.axis.Axes = matlab.graphics.axis.Axes.empty
    %     x (1,:) double
    %     y (1,:) double
    %     sem_y (1,:) double
    % end
    % 
    % arguments (Repeating)
    %     varargin
    % end

    % If ax is empty, create a hidden axes in an invisible figure
    if isempty(ax)
        f = figure('Visible', 'off');
        ax = axes('Parent', f, 'Visible', 'off');
    end

    % Parse optional inputs
    % p = inputParser;
    % addParameter(p, 'Color', [0 0 1]);
    % addParameter(p, 'FaceAlpha', 0.3);
    % parse(p, varargin{:});

    % color = p.Results.Color;
    % color = [0,0,0]; 
    if isempty(color)
        color = [1,1,1];
    end
    % alphaVal = p.Results.FaceAlpha;
    if isempty(alphaVal)
        alphaVal = 0.7;
    end

    % Handle NaNs gracefully
    validIdx = isfinite(x) & isfinite(y) & isfinite(sem_y);
    x = x(validIdx);
    y = y(validIdx);
    sem_y = sem_y(validIdx);

    % Construct fill patch
    xFill = [x, fliplr(x)];
    yFill = [y + sem_y, fliplr(y - sem_y)];

    hold(ax,"on");

    % Plot SEM patch
    fillHandle = fill(ax, xFill, yFill, color, ...
        'EdgeColor', 'none', ...
        'FaceAlpha', alphaVal);

    % hold(ax,"on");

    % Plot main line
    lineHandle = plot(ax, x, y, '-', ...
        'LineWidth', 2, ...
        'Color', color);

    hold(ax,"off");
end
