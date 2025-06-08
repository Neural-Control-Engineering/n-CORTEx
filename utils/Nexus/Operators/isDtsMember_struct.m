function [idx_match] = isDtsMember_struct(T, colID, colVal)
    % rowfun(@(row) compareArgs(row.(colID),colVal),T,'OutputFormat', 'uniform', 'SeparateInputs', false);
    idx_match = arrayfun(@(row) compareArgs(row,colVal),T.(colID));    
end