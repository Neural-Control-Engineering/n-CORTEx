function axisRangeChanged(src, ~, nexObj, nexPtr, axSel, rangeIdx)
    % Update ptr range endpoint (1=start, 2=end) and revisualize.
    nexPtr.(axSel).range(rangeIdx) = src.Value;
    sta = nexPtr.(axSel).range(1);
    stp = nexPtr.(axSel).range(2);
    if sta <= stp
        idxArr = sta:stp;
        nexPtr.(axSel).indices = idxArr;
        % Sta/Stp own the Pointer bus — push the new range as the selection.
        ptrBus = nexObj.collector.Pointer;
        if ~isempty(ptrBus) && isprop(ptrBus, 'selections') ...
                && isfield(ptrBus.selections, axSel) ...
                && isfield(ptrBus.selKeys, axSel)
            nVals  = numel(ptrBus.selKeys.(axSel));
            newSel = idxArr(idxArr >= 1 & idxArr <= nVals);
            ptrBus.selections.(axSel) = newSel;
            if isfield(ptrBus.listBoxes, axSel) && ~isempty(ptrBus.listBoxes.(axSel)) ...
                    && isvalid(ptrBus.listBoxes.(axSel))
                ptrBus.listBoxes.(axSel).Value = newSel;
            end
        end
    end
    nexObj.visualize();
end
