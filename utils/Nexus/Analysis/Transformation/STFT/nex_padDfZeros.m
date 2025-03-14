function df_pad =  nex_padDfZeros(df, windowLen)
    % Get the size of the input DataFrame
    [N, M] = size(df);

    % Compute the number of padding columns for each side
    padCols = floor(windowLen / 2);   

    % Create left and right padding matrices (N × padCols)
    leftPadding = zeros(N, padCols);
    rightPadding = zeros(N, padCols);

    % Concatenate padding on both sides of df
    df_pad = [leftPadding, df, rightPadding];
end