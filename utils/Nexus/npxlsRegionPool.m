function npxlsRegionPool(nexon, shank, timeCourse, poolingMethod)
    % dataFrame = timeCourse.dataFrame;
    dataFrame = timeCourse.DF.df;
    regMap = shank.regMap;
    % sorted region grouping
    regionGroups = findgroups(regMap.region);
    regionGroups_sort = [];
    m=1;
    for i = 1:length(regionGroups)        
        if i~=1
            if regionGroups(i) ~= regionGroups(i-1)
                m = m+1;
            end
        end
        regionGroups_sort = [regionGroups_sort; m];
    end
    regionGroups = regionGroups_sort;
    % pooling action
    switch poolingMethod
        case "average"
            pooledDataFrame = splitapply(@(x) mean(x,1), dataFrame(1:size(regionGroups,1),:), regionGroups);
    end
    pooledRegMapChan = flip([1:size(pooledDataFrame,1)]',1);
    pooledRegMapReg = (splitapply(@(x) x(1), regMap.region, regionGroups));
    pooledRegMapColor = splitapply(@(x) x(1), regMap.color, regionGroups);    
    pooledRegMap = table(pooledRegMapChan, pooledRegMapReg, pooledRegMapColor, 'VariableNames', ["channel", "region", "color"]);
    timeCourse.dataFrame = pooledDataFrame;
    timeCourse.DF.df = pooledDataFrame;
    timeCourse.UserData.tilePtr = 0;
    updateTimeCourse(shank, timeCourse, pooledRegMap);
end