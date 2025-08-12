function df_trimmed = nex_trimDf(df, dim, idxs)
    % Create a full index array for all dimensions
    subs = repmat({':'}, 1, ndims(df));  
    subs{dim} = idxs;  % Replace the target dimension with the specified indexes    
    % Trim using indexing
    df_trimmed = df(subs{:});
end