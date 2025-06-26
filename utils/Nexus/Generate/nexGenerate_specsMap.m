function LUT_specsMap = nexGenerate_specsMap(paramIDs)
    
    n = numel(paramIDs);
    idxs_params = [1:n];
    % Generate random RGB values [0, 255]
    rng('shuffle');  % optional: seed for randomness
    rgbVals = randi([0, 255], n, 3);

    % Convert to hex string format 'RRGGBB'
    hexColors = strings(n, 1);
    for i = 1:n
        hexColors(i) = sprintf('%02X%02X%02X', rgbVals(i,1), rgbVals(i,2), rgbVals(i,3));
    end

    LUT_specsMap = table(idxs_params', paramIDs', hexColors,'VariableNames',{'index','param','color'});
end