function [Z, L] = nexOp_accumCols(X, Y, L)
    % accumulate discretely separated rows (by X) of data (Y) into a 
    X_G = findgroups(X); % discretize into integral bins
    Z = splitapply(@(x) {x}, Y, X_G)';
    L = splitapply(@(x) {x}, L, X_G)';
    L = cellfun(@(l) unique(l), L, "UniformOutput",true);
    maxLen = max(cellfun(@(z) size(z,1), Z, "UniformOutput", true));
    Z_imputeNan = cellfun(@(z) nexOp_padArray(z, (maxLen - size(z,1)), nan), Z, "UniformOutput", false);
    Z = cat(2, Z_imputeNan{:});
end