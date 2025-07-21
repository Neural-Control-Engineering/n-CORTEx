function LUT_eventMap = nexGenerate_eventMap(IDs_events)
    % nexGenerate_eventMap Generate a lookup table of events and hex colors.
    %
    % Input:
    %  IDs_events - cell array or string array of events names
    %
    % Output:
    %   LUT_eventMap - table with columns:
    %       - Event: string
    %       - Color: string in 'RRGGBB' hex format

    % Convert to string array if needed
    if iscell(IDs_events)
        IDs_events = string(IDs_events);
    end

    n = numel(IDs_events);

    % Generate random RGB values [0, 255]
    rng('shuffle');  % optional: seed for randomness
    rgbVals = randi([0, 255], n, 3);

    % Convert to hex string format 'RRGGBB'
    hexColors = strings(n, 1);
    for i = 1:n
        hexColors(i) = sprintf('%02X%02X%02X', rgbVals(i,1), rgbVals(i,2), rgbVals(i,3));
    end

    % Create output table
    LUT_eventMap = table(IDs_events(:), hexColors, ...
        'VariableNames', {'event', 'color'});
end