function [binAvgs, binIDs] = nexAnalysis_averagePool(df, poolMap, dim)
    [binEdges, binIDs] = poolMap.getBinEdges();
    % Create a colon index for all dimensions
    % idx = repmat({':'}, 1, ndims(df));
    df_ax = [1:size(df,dim)];
    bins = discretize(df_ax, sort(binEdges));
    
    % Ensure binIDs is a column vector
    bins = bins(:);
    
    % Remove NaNs
    validMask = ~isnan(bins);
    bins = bins(validMask);

    % Prepare data slice based on specified dim
    sz = size(df);
    nd = ndims(df);   
    
    % Collapse the specified dim to a vector for accumarray
    % Move that dim to the first dimension
    permuteOrder = [dim, setdiff(1:nd, dim,"stable")];
    df_Permuted = permute(df, permuteOrder);
    reshapedData = reshape(df_Permuted, sz(dim), []);
    
    % Apply the validMask to select only data with valid binIDs
    reshapedData = reshapedData(validMask, :);

    % Compute binned mean (along dim)
    % binMeans = accumarray(bins, reshapedData, [], @(x) mean(x(:), 1));
    binMeans_pooled = splitapply(@mean, reshapedData, bins);

    % Reshape output to match original size (except dim gets replaced by #bins)
    sz(dim) = size(binMeans_pooled, 1);    
    sz = sz(permuteOrder); % align back to dim of interest (before unpacking)

    % binMeans = ipermute(reshape(binMeans, sz(setdiff(1:nd, dim))), permuteOrder);
    binMeans_reshaped = reshape(binMeans_pooled, sz);
    % permute back to original format            
    binAvgs = permute(binMeans_reshaped, permuteOrder);
    % binMeans = ipermute(reshape(binMeans, sz), permuteOrder);
end