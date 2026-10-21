function [Z_stack, G_stack, S_stack] = nexOp_stackSTAT(STAT)
    % Flatten each df from (D1 x F x D2 x D3 x ...) → (D1*D2*D3*... x F),
    % then stack across STAT rows. All extra-dim ax values propagate to G_stack.
    % F (dim 2) is always preserved as the coordinate/factor space.
    %
    % Row order must match expandAxCol's assumption below: dims ordered
    % [D1, D2, D3, ...] with D1 fastest-varying (column-major), F excluded
    % and moved last. This generalizes what used to be a fixed permute([1,3,2])
    % — correct only for exactly one extra axis beyond D1/F — to any number
    % of extra axes (e.g. a genuine D2 like frequency coexisting with a
    % SWP-sliced-but-not-squeezed singleton dimension).

    % Pre-reshape to 2D — D1 varies fastest (MATLAB column-major)
    df_perm = cellfun(@(df) permute(df, [1, 3:ndims(df), 2]), STAT.df, "UniformOutput", false);
    df_flat = cellfun(@(df, df_orig) reshape(df, [], size(df_orig,2)), ...
                       df_perm, STAT.df, "UniformOutput", false);

    Z_stack = cat(1, df_flat{:});
    try
        cov_flat = cellfun(@(c) reshape(c, [], size(c,2)), STAT.cov, 'UniformOutput', false);
        S_stack  = cat(1, cov_flat{:});
    catch
        S_stack = [];
    end

    statProps = STAT.Properties.VariableNames;
    statProps = statProps(~ismember(statProps, ["df","ax","ptr","cov","sem","labels"]));
    STAT_G    = STAT(:, statProps);

    % STAT-level group labels — repeated once per flattened row of each df
    repHeights = cellfun(@(df) size(df,1), df_flat, "UniformOutput", false);
    G_cell     = table2cell(STAT_G);
    repHeights_mat = repmat(repHeights, 1, size(G_cell,2));
    G_stack = cellfun(@(g, rh) nexOp_repElem(g, rh), G_cell, repHeights_mat, "UniformOutput", false);

    % Sample number within each flattened df
    SN_stack = cellfun(@(df) (1:size(df,1))', df_flat, "UniformOutput", false);
    G_stack  = [G_stack, SN_stack];
    varNames = [STAT_G.Properties.VariableNames, "sampleNumber"];

    %% Expand ax fields — handles arbitrary extra dims beyond D1.
    % For df shape (D1, F, D2, D3, ...), MATLAB column-major reshape means
    % D1 varies fastest. For ax field of length N matching dim k of df:
    %   col = repmat(repelem(axVals, Nbefore), Nafter, 1)
    % where Nbefore = prod of dims before k, Nafter = prod of dims after k.
    % .ax is stored as a cell column by some producers, a plain struct
    % ARRAY column by others (mdlObject.compileSTAT: "STAT.ax(ri).(f) = ..."
    % — paren-indexed, confirmed directly in its own code) — this block
    % silently no-op'd for every struct-array .ax until now, since nothing
    % that reads G's PLAIN columns by name (stat2dm_supervised's G.(tVar),
    % cvPermute's G_test) was affected by G simply lacking these EXTRA
    % columns. A generic consumer that wants per-trial ax identity in G
    % (Nexus WIP.md's MixedEffect scripts) needs it for either storage
    % convention, so handle both rather than keep assuming cell.
    axIsCell = iscell(STAT.ax);
    if ismember('ax', STAT.Properties.VariableNames) && (axIsCell || isstruct(STAT.ax))
        if axIsCell, ax_ref = STAT.ax{1}; else, ax_ref = STAT.ax(1); end
        axFields = fieldnames(ax_ref);
        % Exclude whichever axis(es) own dim 2 (F) — F is already fully
        % represented in Z_stack's columns and must never also appear as a
        % G_stack group-label. Derived by role (ptr.(name).dim==2), not by a
        % hardcoded name like 'latent': that name-based exclusion silently
        % missed the common chans/unit-FTR case (falls into expandAxCol's
        % size-mismatch fallback instead) and would wrongly exclude 'latent'
        % even when it's the real FTR axis being trained on (e.g. classifying
        % on latent-space trajectories from a CEBRA/SSM embedding).
        if ismember('ptr', STAT.Properties.VariableNames)
            ptr_ref = STAT.ptr(1);
            fAxes   = axFields(cellfun(@(f) isfield(ptr_ref, f) && isequal(ptr_ref.(f).dim, 2), axFields));
            if ~isempty(fAxes)
                coIdx = nexOp_coIndexPairs(ax_ref);
                for p = 1:numel(coIdx)
                    pair = coIdx{p};
                    if any(ismember(fAxes, pair)), fAxes = union(fAxes, pair); end
                end
            end
        else
            fAxes = {};
        end
        axFields = axFields(~ismember(axFields, fAxes));
        for k = 1:numel(axFields)
            f = axFields{k};
            if axIsCell
                axCols = cellfun(@(ax_i, df_i) expandAxCol(ax_i.(f), df_i), ...
                    STAT.ax, STAT.df, "UniformOutput", false);
            else
                % STAT.df is still a cell column either way (confirmed
                % above, df_flat/df_perm already cellfun over it) — only
                % .ax's own storage differs, so index it by position
                % instead of cellfun-ing over it directly.
                axCols = cell(height(STAT), 1);
                for ii = 1:height(STAT)
                    axCols{ii} = expandAxCol(STAT.ax(ii).(f), STAT.df{ii});
                end
            end
            G_stack  = [G_stack,  axCols];
            varNames = [varNames, string(f)];
        end
    end

    G_cat   = colfun(@(col) cat(1, col{:}), G_stack)';
    try
        G_stack = table(G_cat{:}, 'VariableNames', varNames);
    catch
        keyboard
    end
end

function col = expandAxCol(axVals, df)
    % Expand axVals to a column matching the flattened row count of df.
    % df shape: (D1, F, D2, D3, ...) — F is dim 2, excluded from flattening.
    sz         = size(df);
    extraSizes = sz([1, 3:end]);          % [D1, D2, D3, ...]
    n          = numel(axVals);
    dimIdx     = find(extraSizes == n, 1);
    if isempty(dimIdx)
        % size mismatch — fall back to truncate/tile to fit
        nTotal = prod(extraSizes);
        col    = repmat(axVals(:), ceil(nTotal/n), 1);
        col    = col(1:nTotal);
        return
    end
    Nbefore = prod(extraSizes(1:dimIdx-1));   % 1 when dimIdx==1
    Nafter  = prod(extraSizes(dimIdx+1:end)); % 1 when dimIdx==last
    col = repmat(repelem(axVals(:), max(1, Nbefore)), max(1, Nafter), 1);
end