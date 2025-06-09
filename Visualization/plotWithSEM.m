function [lineHandle, fillHandle] = plotWithSEM(ax, x, yMatrix, varargin)
    % plotWithSEM Plot mean with SEM shading on specified axes.
    %
    %   [lineHandle, fillHandle] = plotWithSEM(ax, x, yMatrix)
    %   plots the mean of yMatrix (rows = samples, columns = x values)
    %   with shaded standard error of the mean (SEM) on the axes 'ax'.
    %
    %   Additional name-value pairs can be passed to control:
    %     - 'Color' : Line and shading color (default: [0 0 1])
    %     - 'FaceAlpha' : Transparency of SEM fill (default: 0.3)
    %
    % Example:
    %   ax = subplot(1,1,1);
    %   x = 1:10;
    %   y = randn(5,10);
    %   plotWithSEM(ax, x, y, 'Color', [0.2 0.4 0.8]);

    arguments
        ax (1,1) matlab.graphics.axis.Axes
        x (1,:) double
        yMatrix (:,:) double
    end
    
    arguments (Repeating)
        varargin
    end
    
    % Parse optional inputs
    p = inputParser;
    addParameter(p, 'Color', [0 0 1]);
    addParameter(p, 'FaceAlpha', 0.3);
    parse(p, varargin{:});
    
    color = p.Results.Color;
    alphaVal = p.Results.FaceAlpha;
    
    % Compute mean and SEM
    meanY = mean(yMatrix, 1);
    semY = std(yMatrix, 0, 1) ./ sqrt(size(yMatrix,1));
    
    % Construct fill patch
    xFill = [x, fliplr(x)];
    yFill = [meanY + semY, fliplr(meanY - semY)];
    
    % Plot SEM patch
    fillHandle = fill(ax, xFill, yFill, color, ...
        'EdgeColor', 'none', ...
        'FaceAlpha', alphaVal);
    
    % Plot mean line
    lineHandle = plot(ax, x, meanY, '-', ...
        'LineWidth', 2, ...
        'Color', color);
end
