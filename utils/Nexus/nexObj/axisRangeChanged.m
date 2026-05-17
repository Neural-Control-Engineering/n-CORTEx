function axisRangeChanged(src, ~, nexObj, nexPtr, axSel, rangeIdx)
    % Update ptr range endpoint (1=start, 2=end) and revisualize.
    nexPtr.(axSel).range(rangeIdx) = src.Value;
    sta = nexPtr.(axSel).range(1);
    stp = nexPtr.(axSel).range(2);
    if sta <= stp
        idxArr = sta:stp;
        nexPtr.(axSel).indices = idxArr;
        % Mirror into Pointer bus so RESULTS per-row syncs see the same selection
        ptrBus = nexObj.collector.Pointer;
        if ~isempty(ptrBus) && isprop(ptrBus, 'selections') ...
                && isfield(ptrBus.selections, axSel)
            ptrBus.selections.(axSel) = idxArr;
        end
    end
    nexObj.visualize();
end
