function df_NT = mat2NT(df)
    % Reshape channel vector to Nx4 neuropixels tile layout.
    % Handles both:
    %   2D: (n_chans x 1)   -> (H x 4)        greyscale
    %   3D: (n_chans x 3)   -> (H x 4 x 3)    truecolour RGB
    W       = 4;
    n_chans = size(df, 1);
    n_rgb   = size(df, 2);       % 1 = greyscale, 3 = RGB
    H       = ceil(n_chans / W);
    n_pad   = H * W - n_chans;

    if n_rgb == 3
        df     = [df; zeros(n_pad, 3, 'like', df)];
        df_NT  = permute(reshape(df, [W, H, 3]), [2, 1, 3]);  % (H x W x 3)
    else
        df     = [df(:); zeros(n_pad, 1, 'like', df)];
        df_NT  = reshape(df, [W, H])';                         % (H x W)
    end
end