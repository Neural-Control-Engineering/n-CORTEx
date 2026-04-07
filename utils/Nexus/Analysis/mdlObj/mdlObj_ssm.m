classdef mdlObj_ssm < mdlObject

    properties
        SYS=struct();
    end

    methods
        function mdlObj = mdlObj_ssm(Parent, Origin, dfID_source)            
            % Directly import the submodule
            % args = extractMethodCfg('model_ssm');
            % neural network handle to train and infer from a neural
            mdlObj = mdlObj@mdlObject(Parent, Origin, "ssm", dfID_source);
            mdlObj.py.np = py.importlib.import_module('numpy');
            sklearnPreProc = py.importlib.import_module('sklearn.preprocessing');
            mdlObj.Scaler.model = sklearnPreProc.StandardScaler();
            % mdlObj.cfg.fitCfg = nex_generateCfgObj(str2func("nexFit_ssm"));
            % Reducer: placeholder with no blocks — setBlocks() called by initReducer at fit time
            mdlObj.Reducer = mdlObj_reducer("pca", mdlObj.cfg.fitCfg.entryParams.reducerDim);
            mdlObj.domain.FTR = mdlObj.domain.D2(1);   % default: first non-t axis; updated by Domain bus
       
        end

        function locateDataset(mdlObj)

        end

        function Y = infer(mdlObj, X)
        end

        function train(mdlObj)
        end

        function formatSample(X, Y)
        end

        function initReducer(mdlObj)
            % Build block structure from pMap for domain.FTR(1) using the
            % live axis values from Origin.DF_postOp.  Called at the top of
            % nexFit_ssm so the partition reflects the current pMap state.
            ftrAxis = char(mdlObj.domain.FTR(1));
            axis    = mdlObj.Origin.DF_postOp.ax.(ftrAxis);
            if ~isfield(mdlObj.pMap, ftrAxis) || ~ mdlObj.cfg.fitCfg.entryParams.isBlock
                % fprintf('[mdlObj_ssm] pMap has no entry for FTR="%s" — single-block fallback\n', ftrAxis);
                mdlObj.Reducer.setBlocks([axis(1), axis(end)]);
                mdlObj.Reducer.MDL.ax.binLabels = string(ftrAxis);
                return;
            end
            % if mdlObj.cfg.fitCfg.entryParams.isBlock
            [binEdges, ~, binLabels, ~] = mdlObj.pMap.(ftrAxis).getBinEdges(axis);
            % else
                % binEdges = [];
            % end



            nComp    = mdlObj.cfg.fitCfg.entryParams.reducerDim;
            mdlObj.Reducer.MDL.nComponents  = nComp;
            mdlObj.Reducer.setBlocks(binEdges);
            mdlObj.Reducer.MDL.ax.binLabels = string(binLabels(:)');   % (1 x num_blocks) string
            fprintf('[mdlObj_ssm] Reducer: %d blocks, %d components/block  [%s]\n', ...
                numel(mdlObj.Reducer.MDL.ax.block), nComp, strjoin(mdlObj.Reducer.MDL.ax.binLabels, ", "));
        end

        function applyDomainBus(mdlObj)
            % Read collector.Domain and write into mdlObj.domain.
            % Mirrors nexObj_stateSpace.applyDomainBus().
            if isempty(mdlObj.collector) || ~isfield(mdlObj.collector, 'Domain')
                return;
            end
            domSel = nex_returnSelectionMask(mdlObj.collector.Domain);
            if ~isequal(domSel.D1, "")
                mdlObj.domain.D1 = domSel.D1;
            end
            if ~isequal(domSel.FTR, "")
                mdlObj.domain.FTR = domSel.FTR;
            end
        end

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
        %     d1Sel = mdlObj.domain.D1(1);
        %     % mdlObj.DM = stat2dm_batch(mdlObj, d1Sel);
        %     mdlObj.DM = stat2dm_stack(mdlObj, d1Sel);
        % end

        function DF_Z = transform(mdlObj, DF_X)
            % Use learned weights to project emission into state-space
            % DF_X.df: (T x channels) or (T x channels x batch)
            % For 3D input, batch dim is passed to dynamax filter as (batch x T x n_components)
            disp("transforming ssm...")
            jnp = py.importlib.import_module('jax.numpy');
            np  = py.importlib.import_module('numpy');
            X       = DF_X.df;
            origSize = size(X);
            isBatch  = ndims(X) == 3;

            % Unstack to 2D for sklearn Scaler/Reducer
            X_perm = permute(X,[1,3,2]); % put reshape-able dimensions in the first two
            X_2d = reshape(X_perm, [], origSize(2));
            X_2d_py      = mdlObj.py.np.array(X_2d);
            X_scaled_mat = double(mdlObj.Scaler.model.transform(X_2d_py));
            X_dr         = mdlObj.Reducer.transform(X_scaled_mat);   % block-aware, returns MATLAB double
            nComp        = size(X_dr, 2);

            % Pass as single sequence (T_total x n_components) regardless of input shape
            emissions = jnp.asarray(mdlObj.py.np.array(double(X_dr)));

            if ~isempty(X)
                try
                    Z = mdlObj.W.filter(emissions);
                    % mdlObj.model.filter(emissions);
                catch e
                    disp(getReport(e));
                    DF_Z = [];
                    return
                end
                Z_mu  = double(np.asarray(Z.filtered_means));   % (T_total x state_dim)
                Z_cov = double(np.asarray(Z.filtered_covariances));

                if isBatch
                    % Restack to (T x state_dim x batch)
                    % Z_mu  = reshape(Z_mu,  [origSize(1), origSize(3), nComp]);
                    stateDim = mdlObj.cfg.fitCfg.entryParams.stateDim;
                    Z_mu = reshape(Z_mu, [origSize(1), origSize(3), stateDim]);
                    Z_mu  = permute(Z_mu,  [1 3 2]);
                    Z_cov = reshape(Z_cov, [origSize(1), origSize(3), stateDim, stateDim]);
                    Z_cov = permute(Z_cov, [1 3 4 2]);
                end

                DF_Z.df  = Z_mu;
                DF_Z.cov = Z_cov;
                DF_Z.ax=DF_X.ax;
                DF_Z.ax.(mdlObj.domain.D1) = DF_X.ax.(mdlObj.domain.D1);
                DF_Z.ax.latent = 1:size(Z_mu, 2);
                DF_Z = nex_initAxisPointer_v2(DF_Z);
            else
                DF_Z = [];
            end
        end

        function saveFit(mdlObj, uniqueID)
            % save model weights
            nexon = mdlObj.nexon;
            params = nexon.console.BASE.params;
            % save to FTR             
            mdlSave.W=mdlObj.W;
            mdlSave.model=mdlObj.model;
            mdlSave.Reducer=mdlObj.Reducer;
            mdlSave.Scaler=mdlObj.Scaler;
            savePath = params.paths.Data.FTR.local;
            savePath = fullfile(savePath,sprintf("mdlObj_ssm_%s.mat",uniqueID));
            save(savePath,"mdlSave");            
            fprintf("Model: %s_%s saved successfully", mdlObj.modelID, uniqueID);
        end

    end
end