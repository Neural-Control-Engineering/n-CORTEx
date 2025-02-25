function df_pad = nex_padDf(df, windowLen)
    % Get the size of the input DataFrame
    [N, M] = size(df);

    % Compute the number of padding columns
    padCols = windowLen/2 - 1;

    % Create a padding matrix of size N × padCols
    padding = zeros(N, padCols);

    % Concatenate padding on the left side of df
    df_pad = [padding, df];
end