function LUT = buildLUT_map(list_IDs)
    %
    % Input:
    %   list_phases - cell array or string array of phase names
    %
    % Output:
    %   LUT_phaseMap - table with columns:
    %       - Phase: string
    %       - Color: string in 'RRGGBB' hex format

    % Convert to string array if needed
    if iscell(list_IDs)
        list_IDs = string(list_IDs);
    end

    n = numel(list_IDs);

    % Generate random RGB values [0, 255]
    rng('shuffle');  % optional: seed for randomness
    rgbVals = randi([0, 255], n, 3);

    % Convert to hex string format 'RRGGBB'
    hexColors = strings(n, 1);
    for i = 1:n
        hexColors(i) = sprintf('%02X%02X%02X', rgbVals(i,1), rgbVals(i,2), rgbVals(i,3));
    end

    % Create output table
    LUT = table(list_IDs(:), hexColors, ...
        'VariableNames', {'mapID', 'color'});
end