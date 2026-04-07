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

    % Initialize block reducer from Origin.DF_postOp + pMap
    mdlObj.initReducer();

    switch partialFit
        case 0
            DM = mdlObj.DM;

            if ndims(DM) < 3
                % 2D path: single sequence (T x channels)
                DM_py     = mdlObj.py.np.array(double(DM));
                DM_scaled = double(mdlObj.Scaler.model.fit_transform(DM_py));
                DM_dr     = mdlObj.Reducer.fit_transform(DM_scaled);      % (T x total_components)
                DM_scaled_py = mdlObj.py.np.array(DM_dr);
            else
                % 3D path: batched (num_trials x T x channels)
                DM_perm  = permute(DM, [2,1,3]);                          % → (T x num_trials x channels)
                origSize = size(DM_perm);
                DM_2d    = reshape(DM_perm, [], origSize(end));
                DM_py    = mdlObj.py.np.array(DM_2d);
                DM_scaled = double(mdlObj.Scaler.model.fit_transform(DM_py));
                DM_dr    = mdlObj.Reducer.fit_transform(DM_scaled);       % (T*trials x total_components)
                nComponents  = size(DM_dr, 2);
                DM_restacked = reshape(DM_dr, [origSize(1), origSize(2), nComponents]);
                DM_restacked = permute(DM_restacked, [2,1,3]);            % → (num_trials x T x n_components)
                DM_scaled_py = mdlObj.py.np.array(DM_restacked);
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
            
            % mdlObj.W = mdlObj.model.fit_block_diagonal( ...
            %             DM_scaled_py, C_mask, py.int(sum(latPerBlock)), py.int(numIters));
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
    nCompActual = mdlObj.Reducer.MDL.ax.nCompActual;   % (1 x num_blocks)
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
    nCompActual = mdlObj.Reducer.MDL.ax.nCompActual;   % (1 x num_blocks)
    binLabels   = mdlObj.Reducer.MDL.ax.binLabels;     % (1 x num_blocks) string
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
