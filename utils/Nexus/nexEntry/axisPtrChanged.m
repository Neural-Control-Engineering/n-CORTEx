function axisPtrChanged(src, ~, nexObj, nexPtr, axSel, field)
    % field: which ptr subfield to write (default = 'value')
    % Val and Win are independent animation controls — they do NOT drive the
    % Pointer bus.  Sta/Stp (ptr.range, axisRangeChanged) own that sync.
    if nargin < 6, field = 'value'; end
    nexPtr.(axSel).(field) = src.Value;
    if strcmp(field, 'value')
        nexPtr.(axSel).indices = round(src.Value);
    end
    nexObj.visualize();
end