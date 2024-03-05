function exportVisuals(params, visuals, dataStream)
    % write a graphics file of key visuals for a given datastream with N
    % channels reading a series M samples (e.g. size N x M)

    if ~empty(params)
        location = params.paths.visualsPath;
    else
        location = uigetdir;
    end

    for i = 1: length(visuals)
        visual = visuals{i};
        cmd = sprintf("writeGraphics_%s(location, dataStream)", visual);
        evalin("caller",cmd);
    end
end