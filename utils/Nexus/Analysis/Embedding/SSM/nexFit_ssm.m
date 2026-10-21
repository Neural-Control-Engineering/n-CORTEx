function nexFit_ssm(mdlObj, args)

    % CFG HEADER
    stateDim   = args.stateDim;   % default = 3
    reducerDim = args.reducerDim; % default = 20
    isBlock    = args.isBlock;    % default = 0
    numIters   = args.numIters;   % default = 20
    partialFit = args.partialFit; % default = 0

    % Reload pytafix so edits to lgssm_dynamax.py are reflected without
    % restarting the MATLAB Python session.  Reload bottom-up: inner module
    % first, then containing packages, then re-bind mdlObj.model to the
    % refreshed class handle.
    % py.importlib.invalidate_caches();
    % pytafix = py.importlib.import_module('pytafix');
    % py.importlib.reload(pytafix.ssm.lgssm_dynamax);
    % py.importlib.reload(pytafix.ssm);
    % py.importlib.reload(pytafix);
    % mdlObj.model = pytafix.ssm.LGSSM;

    switch partialFit
        case 0
            % mdlObj.DM arrives from getDesignMatrix already scaled
            % (per-trial-stack StandardScaler inside fitReduce), block-PCA
            % reduced (nexHR_fit, one block per region via
            % pMap.chans.divsPerBin=-Inf), and pooled (nexOp_poolStackedDM,
            % one bin per epoch via pMap.t) — a flat (nGroups, nComponents)
            % matrix, the SAME shape every needsHR consumer (PCA/LDA) gets.
            % SSM alone needs real trial/time array dims back: dynamax's
            % batched fit_em/filter treat a 3D (num_trials, T,
            % emission_dim) input as INDEPENDENT per-trial sequences, not
            % one sequence concatenated end-to-end (confirmed directly in
            % the installed dynamax ssm.py, not just this wrapper — see
            % Nexus WIP.md #19) — nexOp_reshapeStackedByTrial reconstitutes
            % that using mdlObj.TRAIN.G's trialIdx/poolAxis-bin bookkeeping,
            % which the shared pooling step kept around for exactly this.
            %
            % needsHR (pMap.chans.divsPerBin<0, the now-normal config per
            % WIP.md #19): mdlObj.DM already scaled (fitReduce) + reduced +
            % pooled -- just reconstitute trial/time array structure.
            %
            % non-needsHR (chans left pool-mode): mdlObj.DM instead arrives
            % via the OLD stat2dm_stack/dmFcn path, raw and UNSCALED
            % (stat2dm_stack never scales) -- scale it here instead, same
            % role/timing as every other non-needsHR mdlObj's own
            % nexFit_*.m scaling its own DM right before its model fit
            % (nexFit_pca.m/nexFit_lda.m/nexFit_umap.m), since this is the
            % only place SSM gets a chance to before handing data to
            % dynamax now that its own bespoke Scaler/Reducer preamble is
            % retired.
            % Gate on TRAIN.G alone -- that's the real "did getDesignMatrix
            % take the needsHR branch" signal. poolAxis itself can
            % legitimately be "" (reduce-only, no deferred pooling axis)
            % while TRAIN.G is still non-empty (getDesignMatrix sets it to
            % fitReduce's raw-stacked G either way) -- requiring poolAxis
            % too would wrongly skip the reshape for that config and feed
            % dynamax a flat, trial-blind array instead.
            poolAxis = nexOp_resolvePoolAxis(mdlObj.pMap);
            if ~isempty(mdlObj.TRAIN.G)
                DM = nexOp_reshapeStackedByTrial(mdlObj.DM, mdlObj.TRAIN.G, poolAxis);
            else
                DM = mdlObj.DM;
                if isstruct(mdlObj.Scaler) && isfield(mdlObj.Scaler, 'model') && ~isempty(mdlObj.Scaler.model)
                    if ndims(DM) == 3
                        % (num_trials,T,chans) -> (T,num_trials,chans) so scaling
                        % sees one row per (time,trial) sample, chans as columns.
                        DM_perm  = permute(DM, [2,1,3]);
                        permSize = size(DM_perm);
                        DM_2d    = reshape(DM_perm, [], permSize(end));
                        DM_2d    = double(mdlObj.Scaler.model.fit_transform(mdlObj.py.np.array(DM_2d)));
                        DM       = permute(reshape(DM_2d, permSize), [2,1,3]);   % -> (num_trials,T,chans)
                    else
                        DM = double(mdlObj.Scaler.model.fit_transform(mdlObj.py.np.array(DM)));
                    end
                end
            end

            if ndims(DM) < 3
                % 2D path: single sequence (T x channels)
                DM_scaled_py = mdlObj.py.np.array(double(DM));
            else
                % 3D path: batched (num_trials x T x channels)
                DM_scaled_py = mdlObj.py.np.array(double(DM));
            end

            % FIT SSM
            switch isBlock
                case 0
                    % Standard unconstrained LGSSM — no block assignment for latents
                    mdlObj.W = mdlObj.model.fit( ...
                        DM_scaled_py, py.int(stateDim), py.int(numIters));
                    nexFit_ssm_buildSYS(mdlObj, []);

                case 1
                    % Block-diagonal emission constraint
                    % stateDim is per-block; totalStateDim = sum(latPerBlock)
                    [C_mask, latPerBlock] = nexFit_ssm_buildCmask(mdlObj, stateDim);
                    mdlObj.W = mdlObj.model.fit_block_diagonal( ...
                        DM_scaled_py, C_mask, py.int(sum(latPerBlock)), py.int(numIters));
                    nexFit_ssm_buildSYS(mdlObj, latPerBlock);
            end

        case 1
            error("partial fit not enabled");
    end

end


% ── Local: build block-diagonal C mask for the SSM emission matrix ────────
function [C_mask, latPerBlock] = nexFit_ssm_buildCmask(mdlObj, stateDimPerBlock)
    % stateDimPerBlock : requested latent states per block (cfg stateDim)
    % latPerBlock(b)   = min(stateDimPerBlock, nCompActual(b))
    %                    — blocks with fewer PCA outputs than requested are clipped
    % totalStateDim    = sum(latPerBlock)  — actual SSM state dim passed to fit
    % C_mask           : (totalEmDim x totalStateDim) numpy array
    np          = py.importlib.import_module('numpy');
    nCompActual = arrayfun(@(r) numel(r.cols), mdlObj.FTR_blockColRanges);   % (1 x num_blocks)
    num_blocks  = numel(nCompActual);
    totalEmDim  = sum(nCompActual);

    % Per-block latent count — clipped where block has fewer channels than requested

    % TEST: restrict latDimPerBlock where nCompActual is less than nComp
    nCompActual(nCompActual < mdlObj.cfg.fitCfg.entryParams.reducerDim)=1;

    latPerBlock   = min(stateDimPerBlock, nCompActual);
    totalStateDim = sum(latPerBlock);

    C_mask_mat = zeros(totalEmDim, totalStateDim);
    rowOffset  = 0;
    colOffset  = 0;
    for b = 1:num_blocks
        r_s = rowOffset + 1;  r_e = rowOffset + nCompActual(b);
        c_s = colOffset + 1;  c_e = colOffset + latPerBlock(b);
        C_mask_mat(r_s:r_e, c_s:c_e) = 1;
        rowOffset = r_e;
        colOffset = c_e;
    end
    C_mask = np.array(C_mask_mat);
end


% ── Local: extract SSM weight matrices and store as DFs in mdlObj.SYS ─────
function nexFit_ssm_buildSYS(mdlObj, latPerBlock)
    % latPerBlock : (1 x num_blocks) latent count per block from buildCmask,
    %               or [] for an unconstrained fit (factorAx is numeric).
    % Populates mdlObj.SYS with DF_A, DF_C, DF_Q, DF_R.
    % Axes use pMap-derived labels expanded per component, e.g.:
    %   latentAx   = ["STN_1","STN_2","GPi_1",...]  (latent dim)
    %   emissionAx = ["STN_1","STN_2","GPi_1",...]  (PCA-reduced emission dim)
    np = py.importlib.import_module('numpy');

    % Extract weight matrices from fitted Python model
    A = double(np.asarray(mdlObj.W.params.dynamics.weights));   % (stateDim x stateDim)
    C = double(np.asarray(mdlObj.W.params.emissions.weights));  % (emissionDim x stateDim)
    Q = double(np.asarray(mdlObj.W.params.dynamics.cov));       % (stateDim x stateDim)
    R = double(np.asarray(mdlObj.W.params.emissions.cov));      % (emissionDim x emissionDim)

    stateDim    = size(A, 1);
    emissionDim = size(C, 1);
    % Block structure read off FTR_blockColRanges (set by getDesignMatrix's
    % needsHR branch via fitReduce) instead of the retired mdlObj.Reducer —
    % same two quantities (count + label per block), different source.
    nCompActual = arrayfun(@(r) numel(r.cols), mdlObj.FTR_blockColRanges);   % (1 x num_blocks)
    binLabels   = string({mdlObj.FTR_blockColRanges.label});                % (1 x num_blocks) string
    num_blocks  = numel(nCompActual);

    % ── Expand labels per component ───────────────────────────────────────
    % emissionAx: each block b contributes nCompActual(b) entries
    emissionAx = nexFit_ssm_expandLabels(binLabels, nCompActual);

    % latentAx: each block b contributes latPerBlock(b) entries when constrained,
    %           otherwise plain numeric ["z1","z2",...,"zN"]
    if ~isempty(latPerBlock)
        latentAx = nexFit_ssm_expandLabels(binLabels, latPerBlock);
    else
        latentAx = "z" + string(1:stateDim);
    end

    % ── DF_A : (stateDim x stateDim) dynamics matrix ─────────────────────
    mdlObj.SYS.DF_A.df             = A;
    mdlObj.SYS.DF_A.ax.latent      = latentAx;      % column (post-synaptic) latents
    mdlObj.SYS.DF_A.ax.latent_row  = latentAx;      % row (pre-synaptic) latents

    % ── DF_C : (emissionDim x stateDim) observation matrix ───────────────
    mdlObj.SYS.DF_C.df             = C;
    mdlObj.SYS.DF_C.ax.emission    = emissionAx;
    mdlObj.SYS.DF_C.ax.latent      = latentAx;

    % ── DF_Q : (stateDim x stateDim) process noise covariance ────────────
    mdlObj.SYS.DF_Q.df             = Q;
    mdlObj.SYS.DF_Q.ax.latent      = latentAx;
    mdlObj.SYS.DF_Q.ax.latent_row  = latentAx;

    % ── DF_R : (emissionDim x emissionDim) observation noise covariance ──
    mdlObj.SYS.DF_R.df                = R;
    mdlObj.SYS.DF_R.ax.emission       = emissionAx;
    mdlObj.SYS.DF_R.ax.emission_row   = emissionAx;

    fprintf('[nexFit_ssm] SYS built: A(%dx%d)  C(%dx%d)  [%s]\n', ...
        stateDim, stateDim, emissionDim, stateDim, strjoin(unique(latentAx, 'stable'), ", "));
end


% ── Local: expand block labels by per-block counts ────────────────────────
function ax = nexFit_ssm_expandLabels(binLabels, countsPerBlock)
    % binLabels     : (1 x B) string — one label per block
    % countsPerBlock: (1 x B) double — number of entries for each block
    % Returns       : (1 x sum(counts)) string, e.g. ["STN_1","STN_2","GPi_1"]
    parts = cell(1, numel(binLabels));
    for b = 1:numel(binLabels)
        n = countsPerBlock(b);
        parts{b} = binLabels(b) + "_" + string(1:n);
    end
    ax = [parts{:}];
end
