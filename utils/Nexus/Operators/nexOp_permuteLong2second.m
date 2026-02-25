function df_permute = nexOp_permuteLong2second(df)
    sz = size(df);
    longDim = find(sz~=1, 1, "first"); % first non-singleton dim
    if isempty(longDim)
        longDim = 1;
    end
    nd = ndims(df);
    % target: make longDim become dimension 2
    if longDim ~= 2
        permuteOrder = 1:nd;
        permuteOrder(permuteOrder==longDim) = [];
        % ensure we have at least two dims in order to insert longDim at pos 2
        if numel(permuteOrder) < 1
            permuteOrder = 1;
        end
        permuteOrder = [permuteOrder(1:min(1,end)), longDim, permuteOrder(min(2,end)+1:end)];
        df_permute = permute(df, permuteOrder);
    else
        df_permute=df;
    end
end