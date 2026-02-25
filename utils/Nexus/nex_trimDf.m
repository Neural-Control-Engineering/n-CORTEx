function df_trimmed = nex_trimDf(df, dim, idxs)
    if ~isempty(df)
        % Create a full index array for all dimensions
        subs = repmat({':'}, 1, ndims(df));  
        subs{dim} = idxs;  % Replace the target dimension with the specified indexes    
        % Trim using indexing
        try
            df_trimmed = df(subs{:});
        catch
            keyboard
        end
    else
        df_trimmed = [];
    end
end