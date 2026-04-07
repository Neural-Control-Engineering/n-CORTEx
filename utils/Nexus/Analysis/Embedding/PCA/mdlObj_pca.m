classdef mdlObj_pca < mdlObject

    properties
    end

    methods
        function mdlObj = mdlObj_pca(Parent, Origin, dfID_source)            
            % Directly import the submodule
            % args = extractMethodCfg('model_ssm');
            % neural network handle to train and infer from a neural
            if isempty(dfID_source)
                dfID_source = Parent.dfID_source;
            end
            mdlObj = mdlObj@mdlObject(Parent, Origin, "pca", dfID_source);
            mdlObj.py.np = py.importlib.import_module('numpy');
            sklearnPreProc = py.importlib.import_module('sklearn.preprocessing');             
            mdlObj.Scaler.model = sklearnPreProc.StandardScaler();
            mdlObj.cfg.fitCfg=nex_generateCfgObj(str2func("nexFit_pca"));
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

        % function getDesignMatrix(mdlObj)
        %     % d1Sel = "t";
        %     d1Sel=mdlObj.domain.D1(1);
        %     mdlObj.DM = stat2dm_stack(mdlObj, d1Sel);
        % end

        function DF_Z = transform(mdlObj, DF_X)
            % Use learned weights to project emission into state-space            
            disp("transforming pca...");
            X = DF_X.df;
            % chanCond = [1:10]; % TEMP            
            % tCond = [1600:2250]; % TEMP
            if ~isempty(X)
                % X = X(:,chanCond);
                origSize = size(X);
                isBatch  = ndims(X) == 3;
    
                % Loop over 3rd dimension, transform each 2D slice independently
                nSlices = origSize(3);
                Z_slices = cell(1, nSlices);
                for k = 1:nSlices
                    X_k      = X(:, :, k);
                    X_k_py   = mdlObj.py.np.array(X_k);
                    X_scaled = mdlObj.Scaler.model.transform(X_k_py);
                    Z_k      = double(mdlObj.model.transform(X_scaled));
                    Z_slices{k} = Z_k;
                end
                Z = cat(3, Z_slices{:});
                % DF_Z=DF_X;
                DF_Z.df=Z;
                % DF_Z.ax=struct;
                DF_Z.ax=DF_X.ax;
                DF_Z.ax.(mdlObj.domain.D1)=DF_X.ax.(mdlObj.domain.D1);
                % DF_Z.ax.t=DF_Z.ax.t(tCond); % TEMP
                DF_Z.ax.factor=[1:size(Z,2)];
                DF_Z = nex_initAxisPointer_v2(DF_Z);            
            else
                DF_Z = [];
            end
        end
    end
end