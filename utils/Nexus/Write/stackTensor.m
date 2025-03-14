function stack = stackTensor(df)    
    N = size(df,1); D = size(df, 2); M = size(df,3);
    stack = reshape(df,  N * M, D);    
end