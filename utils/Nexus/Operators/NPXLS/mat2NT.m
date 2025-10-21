function df_NT = mat2NT(df)
    % reshape to an Nx4 heatmap
    % Four pixels to a row
    W = 4;
    H = ceil(size(df,1) / W);
    numChans_expected = H*W;
    extraRows = zeros(1,numChans_expected-size(df,1));
    df = [df; extraRows'];
    df_NT = reshape(df,[W,H])';
end