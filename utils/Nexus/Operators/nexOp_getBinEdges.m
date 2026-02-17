function [binEdges, binIDs] = nexOp_getBinEdges(axis, divsPerBin)
        % binEdges = round(linspace(axis(1), axis(end), poolMap.divsPerBin*(axis(end)-axis(1))))';
        % binEdges = [axis(1):poolMap.divsPerBin:axis(end)]';
        % nSteps = ceil((axis(end) - axis(1)) / divsPerBin);
        axisTicks = [1:length(axis)];               
        % linearly space steps along the axis  
        binEdges = [axisTicks(1):divsPerBin:axisTicks(end)]';        
        % channel ranges
        binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)],2);
        % binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)],2);
        binIDs = cellfun(@(idRange) sprintf("%d--%d",idRange(1),idRange(2)),binIDs_nums,"UniformOutput",true);
end