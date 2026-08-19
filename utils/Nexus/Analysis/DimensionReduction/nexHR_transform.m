function out = nexHR_transform(data, layout, pMap, models)
% nexHR_transform  Apply a fitted nexHR model tree to new data.
%
%   data   : (N_ctx, inner_dims..., outermost_dim) — same layout as nexHR_fit input
%   layout : struct array, outermost-first, matching the layout used at fit time
%   pMap   : full pMap (same object used at fit time)
%   models : nested cell array returned by nexHR_fit
%
%   out    : (N_ctx, total_compressed_features)  always 2D

    % Base case: flatten all remaining dims except N_ctx
    if isempty(layout)
        out = reshape(data, size(data, 1), []);
        return;
    end

    current      = layout(1);
    inner_layout = layout(2:end);
    pm           = pMap.(current.axID);
    nd           = ndims(data);
    N_ctx        = size(data, 1);

    % Pass-through: strip from layout, recurse with same models
    if pm.divsPerBin >= 0
        out = nexHR_transform(data, inner_layout, pMap, models);
        return;
    end

    % Reduction: apply each block's fitted reducer
    blockSize = abs(pm.divsPerBin);
    nBlocks   = floor(current.n / blockSize);

    np = py.importlib.import_module('numpy');

    block_outs = cell(1, nBlocks);

    for b = 1:nBlocks
        m = models{b};

        % Extract block along last dim
        idx        = (b-1)*blockSize + (1:blockSize);
        S          = repmat({':'}, 1, nd);
        S{nd}      = idx;
        data_block = data(S{:});

        % Move last dim to position 2: (N_ctx, blockSize, inner_dims...)
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

        % Recurse into inner axes using stored inner models
        inner_out = nexHR_transform(data_for_recurse, inner_layout, pMap, m.inner_models);

        % Unmerge: (N_ctx, blockSize * n_inner_feat)
        n_inner_feat = size(inner_out, 2);
        block_feat   = reshape(inner_out, N_ctx, blockSize * n_inner_feat);

        % Apply fitted PCA
        X_py          = np.array(block_feat);
        block_outs{b} = double(m.reducer.transform(X_py));
    end

    out = cat(2, block_outs{:});
end
