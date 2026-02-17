function g = nexDraw_scatter(ax, Z, v)
    numCols = size(Z,2);
    if nargin > 2
        % propagate violin plot face colors
        C = arrayfun(@(vSub) vSub.FaceColor, v, "UniformOutput", false);
    else
        C = repmat({[0,0,0]}, 1, numCols);
    end
    g = [];
    for x = 1:numCols
        idx = x;
        c = C{x};
        % scatter(ax, x + 0.05*randn(sum(idx),1), Z(:,idx), ...
        %     80, 'k', 'filled', 'MarkerFaceAlpha', 0.4);
        numSamples = size(Z(:,idx),1);
        % g = [g, scatter(ax, x + 0.05*randn(numSamples,1), Z(:,idx), ...
        %     80, 'k', 'filled', 'MarkerFaceAlpha', 0.4)];
        g = [g, scatter(ax, x + 0.06*randn(numSamples,1), Z(:,idx), ...
           100,c, 'filled', 'MarkerFaceAlpha', 0.4, 'MarkerEdgeColor', c, 'LineWidth', 1.25)];
    end
end