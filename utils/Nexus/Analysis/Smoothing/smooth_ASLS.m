function DF_asls = smooth_ASLS(DF_psd, args)
% SMOOTH_ASLS  Asymmetric Least Squares baseline smoother
% 
%   DF_asls = smooth_ASLS(DF_psd, args)
%
%   Inputs:
%     DF_psd : vector (Nx1) — input PSD (can be linear or in dB)
%     args   : struct with optional fields:
%         .lam   - smoothness parameter (default 1e6)
%         .p     - asymmetry parameter (default 0.01)
%         .niter - number of iterations (default 10)
%
%   Output:
%     DF_asls : smoothed baseline estimate (same size as DF_psd)
%
%   Example:
%     args.lam = 1e6; args.p = 0.01; args.niter = 10;
%     DF_asls = smooth_ASLS(P_db, args);

    % ---- Defaults ----
    if ~isfield(args, 'lam'), args.lam = 2000; end
    if ~isfield(args, 'p'), args.p = 0.03; end
    if ~isfield(args, 'niter'), args.niter = 5; end

    % CFG HEADER
    lam = args.lam; % default = 2e4
    p = args.p; % default = 0.1
    niter = args.niter; % default = 10

    % Extract PSD vector
    y = DF_psd.df(:);
    L = length(y);

    % Second difference operator
    D = diff(eye(L), 2);

    % Initialize weights
    w = ones(L, 1);

    % Iterative reweighted least squares
    for i = 1:niter
        W = spdiags(w, 0, L, L);
        Z = W + lam * (D' * D);
        z = Z \ (w .* y);
        w = p * (y > z) + (1 - p) * (y < z);
    end

    % Reshape to match input
    DF_asls.df = reshape(z, size(DF_psd.df));
end
