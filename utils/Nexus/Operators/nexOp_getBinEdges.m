function [binEdges, binIDs, binLabels] = nexOp_getBinEdges(axis, divsPerBin)
        % binEdges = round(linspace(axis(1), axis(end), poolMap.divsPerBin*(axis(end)-axis(1))))';
        % binEdges = [axis(1):poolMap.divsPerBin:axis(end)]';
        nSteps = floor(length(axis)/divsPerBin);

        % axisTicks = [1:length(axis)];               
        % linearly space steps along the axis  
        % binEdges = [axisTicks(1):divsPerBin:axisTicks(end)]';      
        % binEdges = floor(linspace(axis(1), axis(end), nSteps))';
        binEdges = floor(linspace(1, length(axis), nSteps))';
        % channel ranges
        axIDs = axis(binEdges)';
        binIDs=axIDs'; % de-transpose for storing
        % binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)-1],2);
        binIDs_nums = num2cell([axIDs(1:end-1),axIDs(2:end)-1],2);
        % binIDs_nums = [binEdges(1:end-1),binEdges(2:end)];
        % binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)],2);
        binLabels = cellfun(@(idRange) sprintf("%d--%d",idRange(1),idRange(2)),binIDs_nums,"UniformOutput",true);        
        % binIDs = arrayfun(@(idRange) sprintf("%d--%d",idRange(1),idRange(2)),binIDs_nums,"UniformOutput",true);
end