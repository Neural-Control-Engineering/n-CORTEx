function DF_out = distance_mahalanobis(DF_in, args)

    % CFG HEADER
    d1 = args.d1; % default = 1

    % select baseline trajectory
    x1Sel = args.x1Sel;    

    % filter X1 and iterate X2
    D = mahal(X1, X2);
end