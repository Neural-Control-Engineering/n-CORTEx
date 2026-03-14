classdef mdlObj_cebra < mdlObject

    properties        
    end

    methods
        function obj = mdlObj_cebra(Parent, Origin, dfID_source, predictorID)            
            % cebra = py.importlib.import_module('cebra');
            % args = extractMethodCfg('model_cebra');
            % % neural network handle to train and infer from a neural
            % mdlObj.modelObj = model_cebra(cebra, args);                        
            if nargin < 4
                predictorID=[];
            end
            obj = obj@mdlObject(Parent, Origin, "cebra", dfID_source, predictorID);            
            obj.py.np = py.importlib.import_module('numpy');
            sklearnPreProc = py.importlib.import_module('sklearn.preprocessing'); 
            obj.py.stdScaler = sklearnPreProc.StandardScaler();            
            obj.cfg.fitCfg=nex_generateCfgObj(str2func("nexFit_cebra"));
            obj.cfg.dmCfg.format="cebra";
            obj.domain.D1="t";
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
            mdlObj.model.partial_fit(X_py, Y_py);        
            
        end

        % function getDesignMatrix(mdlObj)
        %     d1Sel=mdlObj.domain.D1(1);
        %     mdlObj.DM = stat2dm_cebra(mdlObj);
        % end

        % function Z = transform0(mdlObj, X)
        %     np = py.importlib.import_module('numpy');
        %     X_py = np.ascontiguousarray(np.array(double(X)));   
        %     X_scaled = mdlObj.py.stdScaler.transform(X_py);
        %     Z_py = mdlObj.model.transform(X_scaled);
        %     Z = double(np.array(Z_py));
        % end

        function DF_Z = transform(mdlObj, DF_X)
            % Use learned weights to project emission into state-space            
            disp("transforming cebra...");
            DF_Z = DF_X;
            DF_Z = rmfield(DF_Z,"ptr");
            DF_Z = rmfield(DF_Z,"ax");
            X = DF_X.df;
            % chanCond = [1:10]; % TEMP            
            % tCond = [1600:2250]; % TEMP
            if ~isempty(X)
                % X = X(:,chanCond);
                np = py.importlib.import_module('numpy');
                % X_py = mdlObj.py.np.array(X); 
                X_py = np.array(X); 
                X_scaled = mdlObj.py.stdScaler.transform(X_py);
                % Z_py = mdlObj.model.fit_transform(X_scaled);
                Z_py = mdlObj.model.transform(X_scaled);
                Z = double(Z_py);
                % DF_Z=DF_X;
                DF_Z.df=Z;
                % DF_Z.ax=struct;
                DF_Z.ax.(mdlObj.domain.D1)=DF_X.ax.(mdlObj.domain.D1);                
                % DF_Z.ax.t=DF_Z.ax.t(tCond); % TEMP
                DF_Z.ax.pc=[1:size(Z,2)];
                DF_Z = nex_initAxisPointer_v2(DF_Z);            
            else
                DF_Z = [];
            end
        end
    end
end