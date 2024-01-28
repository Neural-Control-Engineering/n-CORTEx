function sessionParams = setSessionParams(ops)
    % ops.phases = {'1','2','3'};
    ops.phases = {'spontaneous','L-hind-paw','R-hind-paw'};
    ops.ctxModalities = {'npxls','pgx'}
    ops.npxlsSN = {'1234645','3344568'}
    sessionParams = ops;
end