function [v, e, nullMu, nullHi] = nexOp_barStatFromScores(df_i, ax_i, ptr_i, ptrBus)
% Reduce one CV-result row's N-D score array (dims named in ax_i — always
% including fold/perm, plus any number of other axes such as t/unit) down
% to a single bar value + error, plus a null-distribution reference:
%   1. Window every axis OTHER than fold/perm to the CURRENT Pointer bus
%      selection for that axis (matched by VALUE via ptrBus.selKeys, not
%      raw position — robust to any per-row axis reordering). An axis with
%      no Pointer selection, or a "select all" selection (this codebase's
%      established pass-through convention), is left untouched.
%   2. fold is always aggregated: mean over folds (real, perm index 1) for
%      the bar value, SEM for its error — never individually windowed.
%   3. perm (index 2:end, pooled across folds and any remaining collapsed
%      dims) becomes the null reference: mean and 95th percentile.
%
%   df_i   — one row's N-D score array (R.df{i})
%   ax_i   — that row's axis-value struct (R.ax{i}), one field per dim
%   ptr_i  — that row's axis-pointer struct/object (R.ptr{i}), giving
%            ptr_i.(field).dim for each axis in ax_i
%   ptrBus — the viewer's collector.Pointer bus (selections/selKeys)

    S = repmat({':'}, 1, ndims(df_i));
    axFields = setdiff(fieldnames(ax_i), {'fold', 'perm'}, 'stable');
    for k = 1:numel(axFields)
        f = axFields{k};
        if ~isfield(ptrBus.selections, f) || ~isfield(ptrBus.selKeys, f)
            continue;
        end
        selIdx  = ptrBus.selections.(f);
        allVals = ptrBus.selKeys.(f);
        if isempty(selIdx) || numel(selIdx) >= numel(allVals)
            continue;   % "select all" — pass-through, same convention as applyPointer
        end
        selVals = allVals(selIdx);
        rowVals = ax_i.(f);
        if isnumeric(selVals) && isnumeric(rowVals)
            keep = ismember(rowVals, selVals);
        else
            keep = ismember(string(rowVals), string(selVals));
        end
        if ~any(keep) || all(keep), continue; end
        dim = ptr_i.(f).dim;
        if isempty(dim), continue; end
        S{dim} = find(keep);
    end
    scores = df_i(S{:});

    permDim = ptr_i.perm.dim;

    realIdx = repmat({':'}, 1, ndims(scores)); realIdx{permDim} = 1;
    nullIdx = repmat({':'}, 1, ndims(scores)); nullIdx{permDim} = 2:size(scores, permDim);

    real_sc = scores(realIdx{:});
    null_sc = scores(nullIdx{:});

    v = mean(real_sc(:), 'omitnan');
    n = sum(~isnan(real_sc(:)));
    e = std(real_sc(:), 0, 'omitnan') / sqrt(max(n, 1));
    nullMu = mean(null_sc(:), 'omitnan');
    nullHi = prctile(null_sc(:), 95);
end
