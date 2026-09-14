function X_stack = nexOp_stackSamples(STAT, stackMode, dnSel)
    % prepare a batch-wise X for scalable model fitting
    dfCol = nexOp_trimDfCol(STAT.df);
    % concatenate dfs along first dimension
    nDims = cellfun(@(x) ndims(x), dfCol, "UniformOutput", false);
    nDims = max(cat(1,nDims{:}));
    catDim = nDims+1;    
    % put time dimension into first slot
    if dnSel == "None"
        dfCol_dn = dfCol;
    else
        permuteOrders_dn = arrayfun(@(ptr) [ptr.(dnSel).dim, setdiff([1:nDims], ptr.(dnSel).dim)], STAT.ptr, "UniformOutput", false);
        dfCol_dn = cellfun(@(df, permOrder) permute(df, permOrder), dfCol, permuteOrders_dn, "UniformOutput", false);
    end
    switch stackMode
        case "batch"
            % permute batch dim  (last spot) into the first spot
            X_stack = cat(nDims+1, dfCol_dn{:});
            permuteOrder = [1:ndims(X_stack)];
            permuteOrder = circshift(permuteOrder,1);
            X_stack = permute(X_stack, permuteOrder);
        case "stack" % stack along primary dimension
            % dim_d1s = arrayfun(@(ptr) ptr.(dnSel).dim, STAT.ptr, "UniformOutput", false);
            % dim_d1 = mean(cat(1,dim_d1s{:}));
            if dnSel == "None"
                % No D1 axis — all dims are FTR; stack trials into a new leading dim.
                % Mirrors "batch": cat along dim nDims+1, then circshift N to position 1.
                X_stack      = cat(catDim, dfCol_dn{:});
                permuteOrder = circshift(1:ndims(X_stack), 1);
                X_stack      = permute(X_stack, permuteOrder);
            else
                X_stack = cat(1, dfCol_dn{:});
            end
    end
end