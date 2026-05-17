function axisPtrChanged(src, ~, nexObj, nexPtr, axSel, field)
    % field: which ptr subfield to write (default = 'value')
    if nargin < 6, field = 'value'; end
    nexPtr.(axSel).(field) = src.Value;
    if strcmp(field, 'value')
        idx = round(src.Value);
        nexPtr.(axSel).indices = idx;
        % Mirror into Pointer bus so RESULTS per-row syncs see the same selection
        ptrBus = nexObj.collector.Pointer;
        if ~isempty(ptrBus) && isprop(ptrBus, 'selections') ...
                && isfield(ptrBus.selections, axSel)
            ptrBus.selections.(axSel) = idx;
        end
    end
    nexObj.visualize();
end