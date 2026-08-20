function [out, models] = nexHR_fit(data, layout, pMap)
% nexHR_fit  Hierarchical recursive block-PCA across multiple feature axes.
%
% Mental model
% ------------
% Each recursion level owns one feature axis (the outermost / last dim of the
% incoming data).  For each non-overlapping block of elements along that axis:
%
%   1. EXTRACT  — slice blockSize elements from the last dim
%   2. EXPOSE   — permute the block dim to position 2 (next to N_ctx)
%   3. MERGE    — fold block dim into N_ctx by reshaping
%                  → inner recursion now sees N_ctx*blockSize "samples"
%   4. RECURSE  — inner levels compress all remaining feature axes
%   5. UNMERGE  — reshape result back to (N_ctx, blockSize × inner_features)
%   6. COMPRESS — fit PCA: (N_ctx, blockSize × inner_feat) → (N_ctx, nComp)
%
% The merge trick lets the inner PCA see block structure as extra samples,
% so each level discovers structure that spans both that block and every
% inner axis simultaneously.
%
% Toy example  (data = [1014, 15, 97],  layout = [{f,97}, {chans,15}])
% -----------------------------------------------------------------------
%   pMap.f.divsPerBin=-8  (blockSize=8, nBlocks=12), reducerDim=3
%   pMap.chans.divsPerBin=-8  (blockSize=8, nBlocks=1), reducerDim=2
%
%   Level 1 — f axis (outermost, nd=3), block b=1:
%     Extract:  data(:, :, 1:8)            [1014, 15,  8]
%     Expose:   permute([1,3,2])           [1014,  8, 15]
%     Merge:    reshape(·, 1014×8, 15)     [8112, 15]
%     Recurse  ────────────────────────────────────────────────────────────
%       Level 2 — chans axis (nd=2), block b=1:
%         Extract:  data(:, 1:8)           [8112,  8]
%         Expose:   permute([1,2]) no-op   [8112,  8]
%         Merge:    reshape(·, 8112×8, 1)  [64896, 1]
%         Recurse  base case (layout=[])   [64896, 1]
%         Unmerge:  reshape(·, 8112, 8×1)  [8112,  8]
%         Compress: PCA 8→2               [8112,  2]
%       ← inner_out                        [8112,  2]  (1 block × 2 comp)
%     Unmerge:  reshape(·, 1014, 8×2)     [1014, 16]
%     Compress: PCA 16→3                  [1014,  3]
%   After 12 f-blocks: cat(2,…)           [1014, 36]  (12 blocks × 3 comp)
%
% Signature
% ---------
%   data   : (N_ctx, inner_dims..., outermost_dim) — outermost axis is last dim
%   layout : struct array, outermost-first; each entry has .axID and .n
%   pMap   : divsPerBin < 0  → block-PCA, blockSize = abs(divsPerBin)
%            divsPerBin >= 0 → already mean-pooled; pass through
%   out    : (N_ctx, total_compressed_features)   always 2-D
%   models : cell of structs — {b}.mean_, {b}.V, {b}.inner_models

    % Base case: no more feature axes — flatten everything into a feature row
    if isempty(layout)
        out    = reshape(data, size(data, 1), []);
        models = {};
        return;
    end

    current      = layout(1);
    inner_layout = layout(2:end);
    nd           = ndims(data);
    N_ctx        = size(data, 1);

    % Pass-through: axis has no pMap entry, or was already mean-pooled upstream
    if ~isfield(pMap, current.axID) || pMap.(current.axID).divsPerBin >= 0
        [out, models] = nexHR_fit(data, inner_layout, pMap);
        return;
    end
    pm = pMap.(current.axID);

    % Clamp blockSize to actual last-dim size (layout.n may be stale after
    % recursive merges shrink the available dimension).
    % Guard: if actual_n == 1 there is nothing to compress — pass through.
    % (Also avoids MATLAB [N,1] → numpy 1D conversion that breaks sklearn.)
    actual_n = size(data, nd);
    if actual_n <= 1
        [out, models] = nexHR_fit(data, inner_layout, pMap);
        return;
    end
    blockSize = round(abs(pm.divsPerBin));
    if ~isfinite(blockSize) || blockSize >= actual_n
        blockSize = actual_n;
    end
    nBlocks = floor(actual_n / blockSize);
    nComp   = pm.reducerDim;

    np = py.importlib.import_module('numpy');

    block_outs   = cell(1, nBlocks);
    block_models = cell(1, nBlocks);

    for b = 1:nBlocks
        % 1. EXTRACT — slice this block from the last dim
        idx        = (b-1)*blockSize + (1:blockSize);
        S          = repmat({':'}, 1, nd);
        S{nd}      = idx;
        data_block = data(S{:});               % (N_ctx, inner_dims..., blockSize)

        % 2. EXPOSE — bring blockSize to position 2: (N_ctx, blockSize, inner_dims...)
        order      = [1, nd, 2:nd-1];
        data_block = permute(data_block, order);

        % 3. MERGE — fold blockSize into N_ctx so inner recursion sees it as samples
        sz    = size(data_block);
        new_n = sz(1) * sz(2);
        if numel(sz) > 2
            data_for_recurse = reshape(data_block, [new_n, sz(3:end)]);
        else
            data_for_recurse = reshape(data_block, new_n, 1);
        end

        % 4. RECURSE — compress inner axes; inner_out: (N_ctx*blockSize, n_inner_feat)
        [inner_out, inner_m] = nexHR_fit(data_for_recurse, inner_layout, pMap);

        % 5. UNMERGE — restore N_ctx, expose block × inner_feat as flat features
        n_inner_feat = size(inner_out, 2);
        block_feat   = reshape(inner_out, N_ctx, blockSize * n_inner_feat);

        % 6. COMPRESS — PCA across all (blockSize × inner_feat) features per sample
        nComp_actual  = min(nComp, min(size(block_feat)));
        reducer       = model_pca(nComp_actual);
        X_py          = np.ascontiguousarray(np.array(block_feat));
        try
            block_outs{b} = double(reducer.fit_transform(X_py));   % (N_ctx, nComp_actual)
        catch
            keyboard
        end

        block_models{b} = struct('reducer', reducer, 'inner_models', {inner_m});
    end

    % Concatenate all blocks: (N_ctx, nBlocks * nComp_actual)
    out    = cat(2, block_outs{:});
    models = block_models;
end
