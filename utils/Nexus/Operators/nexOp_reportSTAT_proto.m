function STAT = nexOp_reportSTAT_proto(nexObj, fcn, compareVars, groupVars, k, resID)

    % k : arity (pairs, triads, quartets, etc.)
    % resID : result ID

    % Collect all labels
    categories = union(compareVars, groupVars);
    [Y, idxSel] = nexOp_compileLabels(nexObj, categories);
    [Y_enum, G] = nexOp_enumerateCategories(Y, compareVars, groupVars, k); % WATCH FLAG
    
    % groupCols = find(ismember(Y.Properties.VariableNames,groupVars));
    % Y_groups = Y(:,groupCols); % filter    
    % G = findgroups(Y_groups);
    compareElems = [];
    P = perms(compareElems); % combinatorial permutations
    Y_comp = [];
    RESULT = [];
    % for each compareVar, permute and rotate (one row per result)
    for k = 1:length(G)
        group = G(k);
        permutations = [];
        for i = 1:length(permutations)
            combo = permutations(i);
            for j = 1:length(pairs)
                DF1 = combo{1};
                DF2 = combo{2};
                args = extractMethodCfg(func2str(fcn));
                fcn(DF1, DF2, args);
            end
        end
    end
    

end