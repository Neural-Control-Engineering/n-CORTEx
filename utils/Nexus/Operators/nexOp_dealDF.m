function DF_out = nexOp_dealDF(nexon, dfID, Y, fcn, TF_cache, idx_cache)
    if isstruct(Y)
        Y = struct2table(Y);
    end

    if nargin >= 5 && ~isempty(TF_cache)
        % Cache path: map Y.index → pre-loaded, aligned TF entries.
        % idx_cache is sort(Y_G.index) — ascending DTS row indices parallel to TF_cache.
        % ismember maps each Y.index value directly to its cache position.
        [~, cachePos] = ismember(Y.index, idx_cache);
        TF = TF_cache(cachePos);
    else
        idxSel  = ismember((1:height(nexon.console.BASE.DTS))', Y.index);
        idxVals = find(idxSel == 1);
        idxSort = arrayfun(@(idxVal) find(idxVal == Y.index), idxVals);
        dfID    = strrep(dfID, "_df", "");
        TF      = dtsIO_readTF(nexon, dfID, idxSel);
        TF      = TF(idxSort);
    end

    args    = extractMethodCfg(func2str(fcn));
    argList = [TF; {args}];
    try
        DF_out = feval(fcn, argList{:});
        varIDs = Y.Properties.VariableNames;
        L      = varfun(@(V) nexOp_labelMatchup(V), Y);
        L.Properties.VariableNames = varIDs;
        L      = table2struct(L);
        DF_out = mergeStructs(DF_out, L);
    catch e
        % keyboard
        disp(getReport(e));
        DF_out = [];
    end
end
