function P_out = nexAtlas_gaussSmooth(P_in, depths, sigma_um)
% Gaussian-smooth a (n_ch × n_reg) probability matrix along the depth axis.
% Each column is smoothed independently; rows are renormalized to sum to 1.

    D     = abs(depths(:) - depths(:)');        % (n_ch × n_ch) pairwise µm distance
    W     = exp(-0.5 * (D / sigma_um).^2);
    W     = W ./ sum(W, 2);                     % normalize rows
    P_out = W * P_in;
    rsum  = sum(P_out, 2);
    rsum(rsum == 0) = 1;
    P_out = P_out ./ rsum;
end
