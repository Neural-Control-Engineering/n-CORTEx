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
        out = reshape(out(:), size(out, 1), []);  % force materialization: out(:) gathers non-contiguous strides into a new column vector; reshape back gives standard F-contiguous strides
        return;
    end

    current      = layout(1);
    inner_layout = layout(2:end);
    nd           = ndims(data);
    N_ctx        = size(data, 1);

    % Pass-through: no pMap entry for this axis, or already mean-pooled
    if ~isfield(pMap, current.axID) || pMap.(current.axID).divsPerBin >= 0
        out = nexHR_transform(data, inner_layout, pMap, models);
        return;
    end
    pm = pMap.(current.axID);

    % Clamp blockSize to match nexHR_fit exactly; use stored model count for nBlocks
    actual_n = size(data, nd);
    if actual_n <= 1
        out = nexHR_transform(data, inner_layout, pMap, models);
        return;
    end
    blockSize = round(abs(pm.divsPerBin));
    if ~isfinite(blockSize) || blockSize >= actual_n
        blockSize = actual_n;
    end
    nBlocks = numel(models);
    if nBlocks == 0
        error('nexHR_transform:modelMismatch', ...
            'axis="%s": stored nBlocks=0 but actual_n=%d > 1 — fit and transform data have different structure.\nsize(data)=%s  numel(models)=%d', ...
            current.axID, actual_n, mat2str(size(data)), numel(models));
    end

    np  = py.importlib.import_module('numpy');
    dr  = fileparts(mfilename('fullpath'));
    if ~any(strcmp(cellfun(@char, cell(py.sys.path), 'UniformOutput', false), dr))
        py.sys.path().insert(int32(0), dr);
    end
    pym = py.importlib.import_module('nexHR_tracer');
    py.importlib.reload(pym);

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

        % Unmerge in Python (order='F' = MATLAB column-major) to avoid lazy-reshape
        % stride corruption — same fix as nexHR_fit step 5.
        n_inner_feat  = size(inner_out, 2);
        n_feat        = blockSize * n_inner_feat;
        try
            block_feat = np.ascontiguousarray( ...
                np.array(inner_out).reshape(int32(N_ctx), int32(n_feat), pyargs('order', 'F')));
        catch ME
            error('nexHR_transform:ipcContiguity', ...
                'IPC failed serializing inner_out [block=%d size=%s class=%s numel=%d]\n%s', ...
                b, mat2str(size(inner_out)), class(inner_out), numel(inner_out), ME.message);
        end

        % Apply fitted PCA — tracer ensures result is C-contiguous before MATLAB receives it
        block_outs{b} = double(pym.transform_traced(m.reducer, block_feat));
    end

    out = cat(2, block_outs{:});
end
