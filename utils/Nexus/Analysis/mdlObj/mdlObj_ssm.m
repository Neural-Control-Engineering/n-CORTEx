classdef mdlObj_ssm < mdlObject

    properties
    end

    methods
        function mdlObj = mdlObj_ssm(Parent, Origin, dfID_source)            
            % Directly import the submodule
            % args = extractMethodCfg('model_ssm');
            % neural network handle to train and infer from a neural
            mdlObj = mdlObj@mdlObject(Parent, Origin, "ssm", dfID_source);
            mdlObj.py.np = py.importlib.import_module('numpy');
            sklearnPreProc = py.importlib.import_module('sklearn.preprocessing'); 
            mdlObj.py.stdScaler = sklearnPreProc.StandardScaler();
            mdlObj.cfg.fitCfg=nex_generateCfgObj(str2func("nexFit_ssm"));
            mdlObj.domain.D1="t";

            % classID = "ssm";
            % mdlObj.model = model_ssm();                        
            % network, etc.
        end

        function locateDataset(mdlObj)

        end

        function Y = infer(mdlObj, X)
        end

        function train(mdlObj)
        end

        function formatSample(X, Y)
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

        function getDesignMatrix(mdlObj)
            d1Sel = mdlObj.domain.D1(1);
            % mdlObj.DM = stat2dm_batch(mdlObj, d1Sel);
            mdlObj.DM = stat2dm_stack(mdlObj, d1Sel);
        end

        function DF_Z = transform(mdlObj, DF_X)
            % Use learned weights to project emission into state-space            
            disp("transforming ssm...")
            jnp = py.importlib.import_module('jax.numpy');
            np = py.importlib.import_module('numpy');
            X = DF_X.df;
            if ~isempty(X)
                emissions = jnp.asarray(X);
                try
                    Z = mdlObj.W.filter(emissions);
                catch
                    keyboard
                end
                % x_host = jax.device_get(x);   % move off device
                Z_mu_np  = np.asarray(Z.filtered_means);  % ensure ndarray
                % np.float(Z.filtered_means);
                Z_cov_np = np.asarray(Z.filtered_covariances);
                Z_mu = double(Z_mu_np);
                Z_cov = double(Z_cov_np);
                % Z_mll_np=np.asarray(Z.marginal_loglik);
                % Z_mll=double(Z_mll_np);
                % A_np=np.asarray(mdlObj.W.params.dynamics.weights);
                DF_Z.df=Z_mu;
                DF_Z.cov=Z_cov;
                DF_Z.ax.(mdlObj.domain.D1)=DF_X.ax.(mdlObj.domain.D1);
                DF_Z.ax.factor=[1:size(Z_mu,2)];
                DF_Z = nex_initAxisPointer_v2(DF_Z);            
            else
                DF_Z = [];
            end
        end
    end
end