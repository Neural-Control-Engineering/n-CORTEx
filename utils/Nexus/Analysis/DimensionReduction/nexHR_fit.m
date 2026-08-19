function [out, models] = nexHR_fit(data, layout, pMap)
% nexHR_fit  Hierarchical recursive block-PCA across multiple feature axes.
%
%   data   : (N_ctx, inner_dims..., outermost_dim) — outermost axis is last dim
%   layout : struct array, outermost-first, each with .axID (string) and .n (post-pool size)
%   pMap   : full pMap; each entry has .divsPerBin and .reducerDim
%             divsPerBin < 0  → block-PCA at this level; blockSize = abs(divsPerBin)
%             divsPerBin >= 0 → already pooled; pass through to inner axes
%
%   out    : (N_ctx, total_compressed_features)  always 2D
%   models : nested cell array — models{b}.reducer  = fitted sklearn PCA
%                                models{b}.inner_models = models from inner recursion

    % Base case: flatten all remaining dims except N_ctx
    if isempty(layout)
        out    = reshape(data, size(data, 1), []);
        models = {};
        return;
    end

    current      = layout(1);
    inner_layout = layout(2:end);
    pm           = pMap.(current.axID);
    nd           = ndims(data);
    N_ctx        = size(data, 1);

    % Pass-through: axis was already mean-pooled; strip it from layout and recurse
    if pm.divsPerBin >= 0
        [out, models] = nexHR_fit(data, inner_layout, pMap);
        return;
    end

    % Reduction: block-PCA along last dim
    blockSize = abs(pm.divsPerBin);
    nBlocks   = floor(current.n / blockSize);
    nComp     = pm.reducerDim;

    np = py.importlib.import_module('numpy');

    block_outs   = cell(1, nBlocks);
    block_models = cell(1, nBlocks);

    for b = 1:nBlocks
        % Extract block along last dim
        idx        = (b-1)*blockSize + (1:blockSize);
        S          = repmat({':'}, 1, nd);
        S{nd}      = idx;
        data_block = data(S{:});               % (N_ctx, inner_dims..., blockSize)

        % Move last dim (blockSize) to position 2: (N_ctx, blockSize, inner_dims...)
        order      = [1, nd, 2:nd-1];
        data_block = permute(data_block, order);

        % Merge blockSize into N_ctx: (N_ctx*blockSize, inner_dims...)
        sz    = size(data_block);
        new_n = sz(1) * sz(2);
        if numel(sz) > 2
            data_for_recurse = reshape(data_block, [new_n, sz(3:end)]);
        else
            data_for_recurse = reshape(data_block, new_n, 1);
        end

        % Recurse into inner axes
        [inner_out, inner_m] = nexHR_fit(data_for_recurse, inner_layout, pMap);
        % inner_out: (N_ctx*blockSize, n_inner_feat)

        % Unmerge: (N_ctx, blockSize * n_inner_feat)
        n_inner_feat = size(inner_out, 2);
        block_feat   = reshape(inner_out, N_ctx, blockSize * n_inner_feat);

        % Fit PCA at this level
        nComp_actual  = min(nComp, min(size(block_feat)));
        reducer       = model_pca(nComp_actual);
        X_py          = np.array(block_feat);
        block_outs{b} = double(reducer.fit_transform(X_py));   % (N_ctx, nComp_actual)

        block_models{b} = struct('reducer', reducer, 'inner_models', {inner_m});
    end

    out    = cat(2, block_outs{:});   % (N_ctx, nBlocks * nComp_actual)
    models = block_models;
end
