function axisPtrChanged(src, ~, nexObj, nexPtr, axSel, field)
    % field: which ptr subfield to write (default = 'value')
    if nargin < 6, field = 'value'; end
    nexPtr.(axSel).(field) = src.Value;
    nexObj.visualize();
end