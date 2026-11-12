classdef mdlObj_ssm < mdlObject

    properties
        SYS=struct();
    end

    methods
        function mdlObj = mdlObj_ssm(Parent, Origin, dfID_source, headline)
            if nargin < 4, headline = []; end
            % Directly import the submodule
            % args = extractMethodCfg('model_ssm');
            % neural network handle to train and infer from a neural
            mdlObj = mdlObj@mdlObject(Parent, Origin, "ssm", dfID_source, [], headline);
            mdlObj.py.np = py.importlib.import_module('numpy');
            % mdlObj.Scaler.model is already set by the base mdlObject
            % constructor (every subclass gets one) — no need to build a
            % second StandardScaler here.
            % mdlObj.cfg.fitCfg = nex_generateCfgObj(str2func("nexFit_ssm"));
            mdlObj.domain.FTR = mdlObj.domain.D2(1);   % default: first non-t axis; updated by Domain bus

            % mdlObj.Reducer (the old bespoke setBlocks-based mechanism)
            % and its own initReducer override are retired — unified onto
            % the shared needsHR reduce-then-pool sequence (Nexus WIP.md
            % #19): getDesignMatrix's needsHR branch (fitReduce ->
            % nexHR_fit) now does this generically, keyed off whatever
            % sign pMap.chans.divsPerBin actually has — set via the
            % Figure's own pMap config, not here.
        end

        function locateDataset(mdlObj)

        end

        function Y = infer(mdlObj, X)
        end

        function train(mdlObj)
        end

        function formatSample(X, Y)
        end

        % applyDomainBus: no override -- the base mdlObject.applyDomainBus
        % (DN/FTR/MSR/REG, with correct invalidatePrecompile() on REG
        % change) is a strict superset of what this SSM-specific version
        % used to do (DN/FTR only, REG silently dropped -- the exact bug
        % that made the REG listbox inert). Retired, not patched: nothing
        % here needs to differ from the generic version.

        function fit_block_diagonal(mdlObj)

        end

        % function fit(mdlObj)            
        %     % apply training assembly on stored dataset            
        %     % params = mdlObj.modelObj.ParamsLGSSM;
        %     % 
        %     % % Convert MATLAB 3D or 2D data into proper NumPy ndarrays
        %     np = py.importlib.import_module('numpy');        
        %     % jax = py.importlib.import_module('jax');
        %     % pytafix = py.importlib.import_module('pytafix');
        %     % jnp = jax.numpy;
        %     % jr = jax.random;            
        %     % % Plot predictions from a random, untrained model
        %     % init_key = jr.PRNGKey(py.int(42));
        %     % state_dim=3; emission_dim=size(X,2);            
        %     % model = linear_gaussian_ssm.LinearGaussianSSM(py.int(state_dim), py.int(emission_dim));
        %     % params, param_props = model.initialize(init_key);        
        %     % out = py.feval(model.initialize, init_key);
        % 
        %     % testing:
        %     emissions = np.array(X);
        %     stateDim = size()
        %     % fitArgs = 
        %     % mdlObj.cfg.fitCfg.fcn(emissions, fitArgs);
        %     mdlObj.model.fit(emissions, stateDim, num_iters);
        % 
        %     % Ensure doubles
        %     X = double(X);
        %     X_py = np.ascontiguousarray(np.array(X));
        %     emissions_jax = jax.numpy.array(X_py);
        %     [params, marginal_lls] = model.fit_em(params, param_props, X_py, num_iters=py.int(100));
        %     % Y = double(Y);
        %    % inputs
        %     if isempty(inputs)
        %         inputs_py = py.None;
        %     else
        %         inputs_py = py.numpy.array(inputs);
        %     end
        % 
        %     mdlObj.modelObj.LinearGaussianSSM.marginal_log_prob(params, params, emissions_jax);
        % 
        % end

        function partialFit(mdlObj, X, Y)
             % Convert MATLAB 3D or 2D data into proper NumPy ndarrays
            np = py.importlib.import_module('numpy');
        
            % Ensure doubles
            X = double(X);
            Y = double(Y);
        
            % Convert to contiguous NumPy arrays
            X_py = np.ascontiguousarray(np.array(X));
            Y_py = np.ascontiguousarray(np.array(Y));
        
            % Call partial_fit
            mdlObj.modelObj.partial_fit(X_py, Y_py);        
            
        end
         
        % function getDesignMatrix(mdlObj)
        %     dnSel = mdlObj.domain.DN(1);
        %     % mdlObj.DM = stat2dm_batch(mdlObj, dnSel);
        %     mdlObj.DM = stat2dm_stack(mdlObj, dnSel);
        % end

        function DF_Z = transform(mdlObj, DF_X)
            % Use learned weights to project emission into state-space.
            % DF_X.df: raw, pre-reduction — (T x channels) or (T x channels x batch).
            disp("transforming ssm...")
            jnp = py.importlib.import_module('jax.numpy');
            np  = py.importlib.import_module('numpy');

            % Scale+reduce(+pool) via the shared needsHR mechanism (base
            % mdlObject.flattenInput) instead of SSM's own retired
            % Scaler/Reducer.transform calls. G_flat carries trial/bin
            % bookkeeping when needsHR; empty otherwise.
            [X_flat, G_flat] = mdlObj.flattenInput(DF_X);

            poolAxis = nexOp_resolvePoolAxis(mdlObj.pMap);
            if ~isempty(G_flat)
                % Gate on G_flat alone, not poolAxis -- needsHR can be
                % true (and G_flat non-empty) with no designated pool
                % axis at all (reduce-only pMap config); requiring
                % poolAxis too would wrongly skip the reshape and hand
                % dynamax a flat, trial-blind array instead. See
                % nexFit_ssm.m's own identical comment / Nexus WIP.md #19.
                [X_dr, ~, binLabels] = nexOp_reshapeStackedByTrial(X_flat, G_flat, poolAxis);
            else
                X_dr      = X_flat;
                binLabels = [];
            end

            % Pass straight to filter() in whatever shape X_dr actually
            % is -- 2D (single sequence) or 3D (num_trials x T x
            % n_components). Unlike the OLD code, this does NOT flatten a
            % genuine 3D/multi-trial case down to 2D before filtering:
            % pytafix's own filter() vmaps per-trial for ndim==3 input,
            % so Z.filtered_means/_covariances already come back in the
            % matching batched shape -- no manual restack needed (and the
            % old restack, keyed off DF_X's RAW size, would be wrong here
            % anyway once pooling has changed the row count).
            emissions = jnp.asarray(mdlObj.py.np.array(double(X_dr)));

            if ~isempty(X_dr)
                try
                    Z = mdlObj.W.filter(emissions);
                catch e
                    disp(getReport(e));
                    DF_Z = [];
                    return
                end
                Z_mu  = double(np.asarray(Z.filtered_means));
                Z_cov = double(np.asarray(Z.filtered_covariances));

                DF_Z.df  = Z_mu;
                DF_Z.cov = Z_cov;
                DF_Z.ax  = DF_X.ax;
                if ~isempty(binLabels)
                    % Pooled: the DN axis's own tick labels are now the
                    % pooled bin representatives (e.g. epoch labels), not
                    % DF_X's raw, full-resolution values -- those would
                    % mismatch Z_mu's actual (pooled) length.
                    DF_Z.ax.(mdlObj.domain.DN(1)) = binLabels;
                else
                    DF_Z.ax.(mdlObj.domain.DN(1)) = DF_X.ax.(mdlObj.domain.DN(1));
                end
                DF_Z.ax.latent = 1:size(Z_mu, ndims(Z_mu));
                DF_Z = nex_initAxisPointer_v2(DF_Z);
            else
                DF_Z = [];
            end
        end

        function saveFit(mdlObj, uniqueID)
            nexon   = mdlObj.nexon;
            rootDir = nexon.console.BASE.params.paths.Data.FTR.local;
            fitDir  = fullfile(rootDir, sprintf("mdlObj_ssm_%s", uniqueID));
            mkdir(fitDir);
            LGSSM   = py.importlib.import_module('pytafix.ssm.lgssm_dynamax').LGSSM;
            % LGSSM params (JAX arrays) → numpy .npz
            if ~isempty(mdlObj.W)
                mdlObj.W.save(py.str(fullfile(fitDir, "lgssm.npz")));
            end
            % Scaler (sklearn) → pickle — still real and necessary: fitReduce
            % fits mdlObj.Scaler.model now (Nexus WIP.md #19), and applyReduce
            % (inference) must transform through the SAME fitted scaler, not
            % a fresh one.
            LGSSM.save_pickle(mdlObj.Scaler.model, py.str(fullfile(fitDir, "scaler.pkl")));
            % NOT saved here, and nothing else in Nexus saves this for ANY
            % needsHR mdlObj today (pre-existing shared-mechanism gap, not
            % SSM-specific): mdlObj.HR / mdlObj.FTR_layout — the fitted
            % nexHR_fit block-PCA model tree (nested nested Python PCA
            % objects per block). Without persisting these, a fresh
            % loadFit() leaves mdlObj.HR empty, so flattenInput's needsHR
            % branch silently falls through to its non-needsHR fallback
            % instead of actually reducing — loadFit'd SSM inference
            % (transform()) is NOT currently correct for a needsHR fit.
            mdlObj.fitPath = fitDir;
            fprintf("[mdlObj_ssm] saved: %s\n", fitDir);
        end

        function loadFit(mdlObj, fitDir)
            if nargin < 2 || isempty(fitDir)
                fitDir = uigetdir(pwd, "Select SSM fit folder");
                if isequal(fitDir, 0), return; end
            end
            LGSSM = py.importlib.import_module('pytafix.ssm.lgssm_dynamax').LGSSM;
            % Reconstruct LGSSM from .npz
            mdlObj.W     = LGSSM.load(py.str(fullfile(fitDir, "lgssm.npz")));
            mdlObj.model = mdlObj.W.model;
            % Reconstruct Scaler from pickle
            mdlObj.Scaler.model = LGSSM.load_pickle(py.str(fullfile(fitDir, "scaler.pkl")));
            % mdlObj.HR / .FTR_layout are NOT restored here — see saveFit's
            % own comment; not persisted in the first place.
            mdlObj.fitPath = fitDir;
            fprintf("[mdlObj_ssm] loaded: %s\n", fitDir);
        end

    end
end