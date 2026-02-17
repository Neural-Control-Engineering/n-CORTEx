function matchingRows = dtsIO_findMatchingRows(keySel, TF)
    % locate rows that exactly match the 'key'    
    dfType = class(TF);
    switch dfType
        case 'double'
            matchingRows = arrayfun(@(x) ismember(x, keySel), TF);
        case 'string'
            matchingRows = cellfun(@(x) ismember(x, keySel), TF);
    end
end