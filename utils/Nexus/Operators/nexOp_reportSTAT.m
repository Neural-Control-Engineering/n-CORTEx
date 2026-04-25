function STAT = nexOp_reportSTAT(nexObj, dfID, fcn, compareVars, groupVars, k)

    % k : arity (pairs, triads, quartets, etc.)
    % resID : result ID

    % Collect all labels
    categories = union(compareVars, groupVars);
    [Y, idxSel] = nexOp_compileLabels(nexObj, categories);
    [Y_enum, G] = nexOp_enumerateCategories(Y, compareVars, groupVars, k); % WATCH FLAG    
   
    P = nexOp_buildPermutation(Y_enum, compareVars, k);    
    % for each compareVar, permute and rotate (one row per result)
    STAT = {};
    for i = 1:G.nGroups
        groupNum = i;
        rowSel_group = find(ismember(G.byGroup,groupNum));
        Y_G = Y_enum(rowSel_group,:);
        TF = nexOp_permuteApply(nexObj.nexon, dfID, Y_G, P, fcn, []);
        STAT = [STAT; TF];
    end
    STAT=cat(1,STAT{:});
    STAT=struct2table(STAT);

end