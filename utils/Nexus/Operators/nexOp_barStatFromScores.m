function [v, e, nullMu, nullHi, expandLabels] = nexOp_barStatFromScores(df_i, ax_i, ptr_i, ptrBus, expandAxes)
% Reduce one CV-result row's N-D score array (dims named in ax_i — always
% including fold/perm, plus any number of other axes such as t/unit) down
% to bar value(s) + error, plus a null-distribution reference:
%   1. Window every axis OTHER than fold/perm to the CURRENT Pointer bus
%      selection for that axis (matched by VALUE via ptrBus.selKeys, not
%      raw position — robust to any per-row axis reordering). An axis with
%      no Pointer selection, or a "select all" selection (this codebase's
%      established pass-through convention), is left untouched.
%   2. fold is always aggregated: mean over folds (real, perm index 1) for
%      the bar value, SEM for its error — never individually windowed.
%   3. perm (index 2:end, pooled across folds and any remaining collapsed
%      dims) becomes the null reference: mean and 95th percentile.
%   4. EXCEPTION to (1): every axis named in expandAxes is NOT collapsed —
%      each of its kept items keeps its own identity instead. With more
%      than one expandAxes entry, outputs are the FULL CARTESIAN PRODUCT
%      across all of them (e.g. 3 kept channels x 4 kept time bins = 12
%      output elements), not just one axis at a time — nexVisualization_bar
%      turns each expandAxes entry into its own nesting tier, exactly like
%      an extra CTG pick, so N simultaneous expand axes just means N extra
%      tiers, no different in kind from one.
%
%      Every axis in expandAxes ALWAYS contributes at least one kept value
%      per row (or the row is dropped — see below) — an axis that only
%      matches a single item for THIS row still contributes that one value
%      as a trivial (length-1) factor to the product, rather than being
%      treated as "did or didn't expand": this is what lets the cartesian
%      product generalize from 1 to many axes without special-casing which
%      ones actually varied for any given row.
%
%      A row where some expandAxes entry matches ZERO items has no
%      coherent identity along that axis at all — the row is dropped
%      entirely (all-NaN/all-missing outputs, filtered by the caller the
%      same way a NaN bar value already is), rather than guessing.
%
%   df_i        — one row's N-D score array (R.df{i})
%   ax_i        — that row's axis-value struct (R.ax{i}), one field per dim
%   ptr_i       — that row's axis-pointer struct/object (R.ptr{i}), giving
%                 ptr_i.(field).dim for each axis in ax_i
%   ptrBus      — the viewer's collector.Pointer bus (selections/selKeys)
%   expandAxes  — optional axis name list (string array, 0..K axes). Each
%                 named axis with a genuine Pointer selection is expanded
%                 instead of collapsed. Empty/omitted → scalar outputs,
%                 expandLabels = zeros(1,0) string row, exactly today's
%                 single-bar behavior.
%
%   v, e, nullMu, nullHi — scalar, or 1×nItems (nItems = product of each
%                          expandAxes entry's own kept-item count)
%   expandLabels          — nItems×numel(expandAxes) string matrix — column
%                            k holds expandAxes(k)'s own value for each
%                            output element. 1×0 when expandAxes is empty.
%                            A dropped row (see above) returns nItems=1
%                            with every column <missing>.

    if nargin < 5, expandAxes = string.empty(1, 0); end
    expandAxes = string(expandAxes(:))';
    nExpand    = numel(expandAxes);

    S = repmat({':'}, 1, ndims(df_i));
    axFields       = setdiff(fieldnames(ax_i), {'fold', 'perm'}, 'stable');
    expandDims     = nan(1, nExpand);
    expandKeepVals = cell(1, nExpand);
    for k = 1:numel(axFields)
        f = axFields{k};
        if ~isfield(ptrBus.selections, f) || ~isfield(ptrBus.selKeys, f)
            continue;
        end
        selIdx  = ptrBus.selections.(f);
        allVals = ptrBus.selKeys.(f);
        if isempty(selIdx), continue; end
        % axPos: this axis's slot in expandAxes, if it's one of the
        % designated expand axes at all — for it, "select all" must NOT
        % be treated as the usual pass-through no-op, or selecting every
        % item would silently collapse back to a single averaged value
        % instead of expanding (the off-by-one this whole block used to
        % have: N-1 items expanded fine, but N of N fell through to
        % "nothing to filter, skip").
        axPos = find(expandAxes == string(f), 1);
        isExpandCandidate = ~isempty(axPos);
        if numel(selIdx) >= numel(allVals) && ~isExpandCandidate
            continue;   % "select all" — pass-through, same convention as applyPointer
        end
        selVals = allVals(selIdx);
        rowVals = ax_i.(f);
        if isnumeric(selVals) && isnumeric(rowVals)
            keep = ismember(rowVals, selVals);
        else
            keep = ismember(string(rowVals), string(selVals));
        end
        if ~any(keep), continue; end
        if all(keep) && ~isExpandCandidate, continue; end
        dim = ptr_i.(f).dim;
        if isempty(dim), continue; end
        keepIdx = find(keep);
        if isExpandCandidate
            % Keep every selected item in the slice (don't narrow further
            % here) — split out per-item below, after fold/perm handling.
            % A single matching item is still recorded (not treated as
            % "didn't expand") — see header comment on why that's what
            % makes the cartesian product generalize cleanly.
            expandDims(axPos)     = dim;
            expandKeepVals{axPos} = rowVals(keepIdx);
        end
        S{dim} = keepIdx;
    end
    scores = df_i(S{:});

    permDim = ptr_i.perm.dim;

    realIdx = repmat({':'}, 1, ndims(scores)); realIdx{permDim} = 1;
    nullIdx = repmat({':'}, 1, ndims(scores)); nullIdx{permDim} = 2:size(scores, permDim);

    real_sc = scores(realIdx{:});
    null_sc = scores(nullIdx{:});

    if nExpand == 0
        v      = mean(real_sc(:), 'omitnan');
        n      = sum(~isnan(real_sc(:)));
        e      = std(real_sc(:), 0, 'omitnan') / sqrt(max(n, 1));
        nullMu = mean(null_sc(:), 'omitnan');
        nullHi = prctile(null_sc(:), 95);
        expandLabels = strings(1, 0);
        return;
    end

    if any(isnan(expandDims))
        % At least one designated expand axis matched zero items for THIS
        % row — no coherent identity along that axis, so no coherent bar.
        % Return a single dropped row; the caller filters ismissing(...)
        % the same way it already filters a NaN bar value.
        v = NaN; e = NaN; nullMu = NaN; nullHi = NaN;
        expandLabels = strings(1, nExpand);   % all <missing>
        return;
    end

    % expandDims are still real dimensions of real_sc/null_sc at the same
    % positions they had in df_i (indexing a dimension to a scalar/subset
    % never renumbers the others) — enumerate the cartesian product of
    % every expand axis's kept items instead of averaging across any of
    % them. itemCounts(a)==1 (this row only matched one item on that
    % axis) just contributes a trivial factor of 1 to the product — no
    % special-casing needed for "this axis didn't really expand here".
    itemCounts = cellfun(@numel, expandKeepVals);
    nItems     = prod(itemCounts);
    v = nan(1, nItems); e = nan(1, nItems);
    nullMu = nan(1, nItems); nullHi = nan(1, nItems);
    expandLabels = strings(nItems, nExpand);
    idxReal = repmat({':'}, 1, ndims(real_sc));
    idxNull = repmat({':'}, 1, ndims(null_sc));
    subIdx  = cell(1, nExpand);
    for m = 1:nItems
        if nExpand == 1
            % ind2sub requires >=2 size elements — with a single expand
            % axis the linear index already IS the subscript, no
            % conversion needed (this is also, by far, the common case).
            subIdx{1} = m;
        else
            [subIdx{:}] = ind2sub(itemCounts, m);
        end
        for a = 1:nExpand
            idxReal{expandDims(a)} = subIdx{a};
            idxNull{expandDims(a)} = subIdx{a};
            expandLabels(m, a) = string(expandKeepVals{a}(subIdx{a}));
        end
        rs = real_sc(idxReal{:});
        ns = null_sc(idxNull{:});
        v(m) = mean(rs(:), 'omitnan');
        nn   = sum(~isnan(rs(:)));
        e(m) = std(rs(:), 0, 'omitnan') / sqrt(max(nn, 1));
        nullMu(m) = mean(ns(:), 'omitnan');
        nullHi(m) = prctile(ns(:), 95);
    end
end
