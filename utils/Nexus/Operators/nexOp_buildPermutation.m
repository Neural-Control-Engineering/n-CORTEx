function P = nexOp_buildPermutation(Y, compareVars, k)

    if isempty(compareVars)
        P.M = [];
        P.P = [];
        return
    end

    compareVar      = compareVars(1);
    compareVars_sub = setdiff(compareVars, compareVar);
    compareVar      = strrep(compareVar, "--", "_");
    P.varID         = compareVar;
    try
        Y_comp = Y.(compareVar);
    catch
        keyboard
    end

    try
        M = perms(unique(Y_comp));
    catch
        keyboard
    end

    if size(M, 2) >= k
        P.M = M(:, 1:k);
    else
        P.M = M;
    end

    props   = Y.Properties.VariableNames;
    varsIdx = props(ismember(props, strrep(compareVars_sub, "--", "_")));
    Y_perm  = Y(:, varsIdx);
    P.P     = nexOp_buildPermutation(Y_perm, compareVars_sub, k);

end
