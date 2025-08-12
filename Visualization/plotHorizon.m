function [meanDfs, Ax] = plotHorizon(Ax, f, dfSet, color, legItem)
    % color in HSV format
    cDim = color;
    cDim(2) = 50;
    cDim(3) = 70;
    % fh = figure;
    for i = 1:size(dfSet,1)
        df = dfSet{i};
        plot(Ax, f, df,"Color",hsv2rgb(cDim./[360,100,100]))
        hold on
    end
    catDfs = cat(2, dfSet{:});
    meanDfs = mean(catDfs,2);
    plot(Ax, f, meanDfs,"Color",hsv2rgb(color./[360,100,100]),"LineWidth",2)
    % Ax.Legend = [Ax.Legend,legItem];
end