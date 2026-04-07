function [Z_stack, G_stack, S_stack] = nexOp_stackSTAT(STAT)
    % Flatten each df from (D1 x F x D2 x D3 x ...) → (D1*D2*D3*... x F),
    % then stack across STAT rows. All extra-dim ax values propagate to G_stack.
    % F (dim 2) is always preserved as the coordinate/factor space.

    % Pre-reshape to 2D — D1 varies fastest (MATLAB column-major)
    df_perm = cellfun(@(df) permute(df, [1,3,2]), STAT.df, "UniformOutput", false);
    df_flat = cellfun(@(df) reshape(df,[],size(df,3)), df_perm, "UniformOutput",false);
    % df_flat = cellfun(@(df) reshape(df, [], size(df,2)), STAT.df, 'UniformOutput', false);

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
    if ismember('ax', STAT.Properties.VariableNames) && iscell(STAT.ax)
        ax_ref   = STAT.ax{1};
        axFields = fieldnames(ax_ref);
        axFields = axFields(~strcmp(axFields, 'factor'));
        for k = 1:numel(axFields)
            f = axFields{k};
            axCols = cellfun(@(ax_i, df_i) expandAxCol(ax_i.(f), df_i), ...
                STAT.ax, STAT.df, "UniformOutput", false);
            G_stack  = [G_stack,  axCols];
            varNames = [varNames, string(f)];
        end
    end

    G_cat   = colfun(@(col) cat(1, col{:}), G_stack)';
    G_stack = table(G_cat{:}, 'VariableNames', varNames);
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