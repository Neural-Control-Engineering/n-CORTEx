function axisPtrChanged(src, ~, nexObj, nexPtr, axSel, field)
    % field: which ptr subfield to write (default = 'value')
    if nargin < 6, field = 'value'; end
    nexPtr.(axSel).(field) = src.Value;
    if strcmp(field, 'value')
        nexPtr.(axSel).indices = round(src.Value);
    end
    % Bidirectional sync: push the new (value, window) state into the Pointer
    % bus so both controls always reflect the same display window.
    if strcmp(field, 'value') || strcmp(field, 'window')
        ptrBus = nexObj.collector.Pointer;
        if ~isempty(ptrBus) && isfield(ptrBus.selections, axSel) ...
                && isfield(ptrBus.selKeys, axSel)
            nVals  = numel(ptrBus.selKeys.(axSel));
            curVal = round(nexPtr.(axSel).value);
            curWin = nexPtr.(axSel).window;
            if curWin >= nVals
                newSel = 1:nVals;
            else
                half   = round(curWin / 2);
                newSel = max(1, curVal - half) : min(nVals, curVal + half);
            end
            ptrBus.selections.(axSel) = newSel;
            if isfield(ptrBus.listBoxes, axSel) && ~isempty(ptrBus.listBoxes.(axSel)) ...
                    && isvalid(ptrBus.listBoxes.(axSel))
                ptrBus.listBoxes.(axSel).Value = newSel;
            end
        end
    end
    nexObj.visualize();
end