function nexVis_legendStyle(lgd, green)
% Apply standard Nexus dark-theme styling to a legend handle.
    lgd.TextColor = green;
    lgd.Color     = [0 0 0];
    lgd.EdgeColor = green;
    lgd.FontSize  = 6;
end
