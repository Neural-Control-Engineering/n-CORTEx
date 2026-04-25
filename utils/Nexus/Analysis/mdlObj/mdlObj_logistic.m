classdef mdlObj_logistic < mdlObject

    properties
    end

    methods
        function mdlObj = mdlObj_logistic(Parent, Origin, dfID_source, headline)
            if nargin < 4, headline = []; end
            % Directly import the submodule
            % args = extractMethodCfg('model_ssm');
            % neural network handle to train and infer from a neural
            mdlObj = mdlObj@mdlObject(Parent, Origin, "logistic", dfID_source, [], headline);
            mdlObj.py.np = py.importlib.import_module('numpy');
            sklearnPreProc = py.importlib.import_module('sklearn.preprocessing'); 
            mdlObj.py.stdScaler = sklearnPreProc.StandardScaler();
            mdlObj.cfg.fitCfg=nex_generateCfgObj(str2func("nexFit_logistic"));
            mdlObj.cfg.dmCfg.format="supervised";
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

        function Y = predict(mdlObj, X)
            X_py = mdlObj.py.np.array(X);
            Y_py = mdlObj.predict(X_py)
            Y = double(Y_py);
        end

        % function getDesignMatrix(mdlObj)
        %     d1Sel = mdlObj.domain.D1(1);
        %     % mdlObj.DM = stat2dm_batch(mdlObj, d1Sel);
        %     mdlObj.DM = stat2dm_stack(mdlObj, d1Sel);
        % end

        % function DF_Z = transform(mdlObj, DF_X)
        %     % Use learned weights to project emission into state-space            
        %     disp("transforming ssm...")
        %     jnp = py.importlib.import_module('jax.numpy');
        %     np = py.importlib.import_module('numpy');
        %     X = DF_X.df;
        %     if ~isempty(X)
        %         emissions = jnp.asarray(X);
        %         try
        %             Z = mdlObj.W.filter(emissions);
        %         catch
        %             keyboard
        %         end
        %         % x_host = jax.device_get(x);   % move off device
        %         Z_mu_np  = np.asarray(Z.filtered_means);  % ensure ndarray
        %         % np.float(Z.filtered_means);
        %         Z_cov_np = np.asarray(Z.filtered_covariances);
        %         Z_mu = double(Z_mu_np);
        %         Z_cov = double(Z_cov_np);
        %         % Z_mll_np=np.asarray(Z.marginal_loglik);
        %         % Z_mll=double(Z_mll_np);
        %         % A_np=np.asarray(mdlObj.W.params.dynamics.weights);
        %         DF_Z.df=Z_mu;
        %         DF_Z.cov=Z_cov;
        %         DF_Z.ax.(mdlObj.domain.D1)=DF_X.ax.(mdlObj.domain.D1);
        %         DF_Z.ax.factor=[1:size(Z_mu,2)];
        %         DF_Z = nex_initAxisPointer_v2(DF_Z);            
        %     else
        %         DF_Z = [];
        %     end
        % end
    end
end