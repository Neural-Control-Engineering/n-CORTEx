function [v, e, nullMu, nullHi, expandLabels] = nexOp_barStatFromScores(df_i, ax_i, ptr_i, ptrBus, expandAxis)
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
%   4. EXCEPTION to (1): expandAxis, when given and it has a genuine
%      multi-item Pointer selection, is NOT collapsed — each kept item
%      gets its own v/e/nullMu/nullHi/label instead (nexVisualization_bar's
%      2D nested bar case). Every other multi-select axis still collapses
%      via mean as in (1).
%
%   df_i       — one row's N-D score array (R.df{i})
%   ax_i       — that row's axis-value struct (R.ax{i}), one field per dim
%   ptr_i      — that row's axis-pointer struct/object (R.ptr{i}), giving
%                ptr_i.(field).dim for each axis in ax_i
%   ptrBus     — the viewer's collector.Pointer bus (selections/selKeys)
%   expandAxis — optional axis name (char/string). When that axis has a
%                multi-item Pointer selection, outputs are row vectors
%                (one element per kept item, in Pointer-selection order)
%                instead of scalars. "" / omitted / axis not applicable →
%                scalar outputs, expandLabels = string(missing), exactly
%                today's behavior.
%
%   v, e, nullMu, nullHi — scalar, or 1×nItems when expandAxis is active
%   expandLabels         — string(missing), or 1×nItems (expandAxis's own
%                           kept values, one per output element)

    if nargin < 5, expandAxis = ""; end
    expandAxis = string(expandAxis);

    S = repmat({':'}, 1, ndims(df_i));
    axFields = setdiff(fieldnames(ax_i), {'fold', 'perm'}, 'stable');
    expandDim      = [];
    expandKeepVals = [];
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
        keepIdx = find(keep);
        if expandAxis ~= "" && string(f) == expandAxis && numel(keepIdx) > 1
            % Keep every selected item in the slice (don't narrow further
            % here) — split out per-item below, after fold/perm handling.
            expandDim      = dim;
            expandKeepVals = rowVals(keepIdx);
        end
        S{dim} = keepIdx;
    end
    scores = df_i(S{:});

    permDim = ptr_i.perm.dim;

    realIdx = repmat({':'}, 1, ndims(scores)); realIdx{permDim} = 1;
    nullIdx = repmat({':'}, 1, ndims(scores)); nullIdx{permDim} = 2:size(scores, permDim);

    real_sc = scores(realIdx{:});
    null_sc = scores(nullIdx{:});

    if isempty(expandDim)
        v      = mean(real_sc(:), 'omitnan');
        n      = sum(~isnan(real_sc(:)));
        e      = std(real_sc(:), 0, 'omitnan') / sqrt(max(n, 1));
        nullMu = mean(null_sc(:), 'omitnan');
        nullHi = prctile(null_sc(:), 95);
        expandLabels = string(missing);
        return;
    end

    % expandDim is still a real dimension of real_sc/null_sc at the same
    % position it had in df_i (indexing a dimension to a scalar/subset
    % never renumbers the others) — slice one item at a time instead of
    % averaging across it.
    nItems = numel(expandKeepVals);
    v = nan(1, nItems); e = nan(1, nItems);
    nullMu = nan(1, nItems); nullHi = nan(1, nItems);
    idxReal = repmat({':'}, 1, ndims(real_sc));
    idxNull = repmat({':'}, 1, ndims(null_sc));
    for j = 1:nItems
        idxReal{expandDim} = j;
        idxNull{expandDim} = j;
        rs = real_sc(idxReal{:});
        ns = null_sc(idxNull{:});
        v(j) = mean(rs(:), 'omitnan');
        nn   = sum(~isnan(rs(:)));
        e(j) = std(rs(:), 0, 'omitnan') / sqrt(max(nn, 1));
        nullMu(j) = mean(ns(:), 'omitnan');
        nullHi(j) = prctile(ns(:), 95);
    end
    expandLabels = string(expandKeepVals(:))';
end
