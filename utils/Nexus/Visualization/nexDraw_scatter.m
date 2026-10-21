function g = nexDraw_scatter(ax, Z, v)
    numCols = size(Z,2);
    if nargin > 2
        % propagate violin plot face colors -- Violin.m exposes this as
        % the dependent property ViolinColor (reading its internal
        % ViolinPlot.FaceColor patch), not a bare FaceColor property;
        % ViolinColor itself returns a cell (supports up to two colors
        % for split violins), so {1} is the plain RGB triplet needed here.
        C = arrayfun(@(vSub) vSub.ViolinColor{1}, v, "UniformOutput", false);
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