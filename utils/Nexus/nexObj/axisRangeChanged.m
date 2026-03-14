function axisRangeChanged(src, ~, nexObj, nexPtr, axSel, rangeIdx)
    % Update ptr range endpoint (1=start, 2=end) and revisualize.
    nexPtr.(axSel).range(rangeIdx) = src.Value;
    nexObj.visualize();
end
