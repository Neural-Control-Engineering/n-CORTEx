function TF = nexOp_permuteApply(nexon, dfID, Y, P, fcn, match, TF_cache, idx_cache)

    if nargin < 7, TF_cache  = []; end
    if nargin < 8, idx_cache = []; end

    % BASE — no more compareVar nesting; apply fcn per trialNumber group
    if isempty(P.M)
        TF_out = splitapply( ...
            @(Ysub) {nexOp_dealDF(nexon, dfID, Ysub, fcn, TF_cache, idx_cache)}, ...
            table2struct(Y), Y.trialNumber);
        isRes = cellfun(@(DF) ~isempty(DF), TF_out, 'UniformOutput', true);
        TF = TF_out(isRes);
    else
        M     = P.M;
        varID = P.varID;
        TF    = {};
        for i = 1:size(M, 1)
            match   = M(i, :);
            rowSel  = find(ismember(Y.(varID), match));
            Y_filt  = Y(rowSel, :);
            sortIdx = arrayfun(@(item) find(ismember(Y_filt.(varID), item)), ...
                               match', 'UniformOutput', false);
            sortIdx = cat(1, sortIdx{:});
            Y_filt  = Y_filt(sortIdx, :);
            TF = [TF; nexOp_permuteApply(nexon, dfID, Y_filt, P.P, fcn, match, ...
                                          TF_cache, idx_cache)]; %#ok<AGROW>
        end
    end

end
