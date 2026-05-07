function STAT = nexOp_reportSTAT(nexObj, dfID, fcn, compareVars, groupVars, k, nBins)

    % k     : arity (pairs=2, triads=3, ...)
    % nBins : optional — quantile-bin continuous compareVars before enumeration

    if nargin < 7 || isempty(nBins), nBins = []; end

    % Collect all labels
    categories = union(compareVars, groupVars);
    [Y, ~] = nexOp_compileLabels(nexObj, categories);

    [Y_enum, G] = nexOp_enumerateCategories(Y, compareVars, groupVars, k, nBins);
    P           = nexOp_buildPermutation(Y_enum, compareVars, k);

    STAT = {};
    for i = 1:G.nGroups
        rowSel_group = find(ismember(G.byGroup, i));
        Y_G = Y_enum(rowSel_group, :);

        % Pre-load and SLRT-align TF for this group in one bulk read
        idxSel_G       = ismember((1:height(nexObj.nexon.console.BASE.DTS))', Y_G.index);
        [TF_G, drop_G] = nexOp_compileTF(nexObj, idxSel_G, dfID);        
        idx_G          = sort(Y_G.index);
        idx_G          = idx_G(~drop_G);
        Y_G            = Y_G(ismember(Y_G.index, idx_G), :);

        % Apply Pointer window at TF level (slices axes before analysis)
        if ~isempty(TF_G) && isfield(nexObj.collector, 'Pointer') ...
                && ~isempty(nexObj.collector.Pointer)
            TF_G = nexObj.applyPointerTF(TF_G);
        end

        TF   = nexOp_permuteApply(nexObj.nexon, dfID, Y_G, P, fcn, [], TF_G, idx_G);
        STAT = [STAT; TF]; %#ok<AGROW>
    end
    STAT = cat(1, STAT{:});
    STAT = struct2table(STAT);

end
