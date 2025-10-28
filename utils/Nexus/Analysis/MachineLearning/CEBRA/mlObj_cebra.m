classdef mlObj_cebra < handle
    properties
        modelObj
        cfg
    end

    methods
        function mlObj = mlObj_cebra()            
            cebra = py.importlib.import_module('cebra');
            args = extractMethodCfg('model_cebra');
            % neural network handle to train and infer from a neural
            mlObj.modelObj = model_cebra(cebra, args);                        
            % network, etc.
        end

        function locateDataset(mlObj)

        end

        function Y = infer(mlObj, X)
        end

        function train(mlObj)
        end

        function formatSample(X, Y)
        end

        function fit(mlObj)
            % apply training assembly on stored dataset
        end

        function partialFit(mlObj, X, Y)
             % Convert MATLAB 3D or 2D data into proper NumPy ndarrays
            np = py.importlib.import_module('numpy');
        
            % Ensure doubles
            X = double(X);
            Y = double(Y);
        
            % Convert to contiguous NumPy arrays
            X_py = np.ascontiguousarray(np.array(X));
            Y_py = np.ascontiguousarray(np.array(Y));
        
            % Call partial_fit
            mlObj.modelObj.partial_fit(X_py, Y_py);        
            
        end

        function Z = transform(mlObj, X)
            np = py.importlib.import_module('numpy');
            X_py = np.ascontiguousarray(np.array(double(X)));            
            Z_py = mlObj.modelObj.transform(X_py);
            Z = double(np.array(Z_py));
        end
    end
end