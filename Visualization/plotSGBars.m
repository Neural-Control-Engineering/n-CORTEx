function plotSGBars(regMap, P, groups, groupLabels, div)
    switch div
        case 'channel'
            plotSGBars_channels(regMap, P, groups, groupLabels);
        case 'region'
            plotSGBars_regions(regMap, P, groups, groupLabels);
    end
end