function df_pad = nex_padDfMean(df, windowLen)
    % Get the size of the input DataFrame
    [N, M] = size(df);

    % Compute the number of padding columns for each side
    padCols = floor(windowLen / 2);

    % Compute the mean across each row
    rowMeans = mean(df, 2); % N × 1 column vector

    % Create left and right padding matrices (N × padCols)
    leftPadding = repmat(rowMeans, 1, padCols);
    rightPadding = repmat(rowMeans, 1, padCols);

    % Concatenate padding on both sides of df
    df_pad = [leftPadding, df, rightPadding];
end