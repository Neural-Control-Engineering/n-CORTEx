function X_stack = nexOp_stackSamples(STAT, stackMode, d1Sel)
    % prepare a batch-wise X for scalable model fitting
    dfCol = nexOp_trimDfCol(STAT.df);
    % concatenate dfs along first dimension
    nDims = cellfun(@(x) ndims(x), dfCol, "UniformOutput", false);
    nDims = max(cat(1,nDims{:}));
    catDim = nDims+1;    
    % put time dimension into first slot    
    permuteOrders_d1 = arrayfun(@(ptr) [ptr.(d1Sel).dim, setdiff([1:nDims], ptr.(d1Sel).dim)], STAT.ptr, "UniformOutput", false);
    dfCol_d1 = cellfun(@(df, permOrder) permute(df, permOrder), dfCol, permuteOrders_d1, "UniformOutput", false);
    switch stackMode
        case "batch"
            % permute batch dim  (last spot) into the first spot
            X_stack = cat(nDims+1, dfCol_d1{:});
            permuteOrder = [1:ndims(X_stack)];
            permuteOrder = circshift(permuteOrder,1);
            X_stack = permute(X_stack, permuteOrder);
        case "stack" % stack along primary dimension
            % dim_d1s = arrayfun(@(ptr) ptr.(d1Sel).dim, STAT.ptr, "UniformOutput", false);
            % dim_d1 = mean(cat(1,dim_d1s{:}));
            X_stack = cat(1, dfCol_d1{:});
    end
end