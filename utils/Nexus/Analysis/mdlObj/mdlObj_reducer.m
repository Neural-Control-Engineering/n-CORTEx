classdef mdlObj_reducer < handle
    properties
        MDL = struct    % .models{i} = sklearn model; .ax.block{i} = feature indices (1-based)
    end

    methods

        function mdlObj = mdlObj_reducer(modelID, nComponents, binEdges)
            % binEdges : 1-based numeric vector [e1, e2, ..., eN+1] marking bin boundaries.
            %            Bin i spans columns  e_i : e_{i+1}-1  (i < N)
            %            Last bin spans       e_N : e_{N+1}    (closed both ends)
            %            e.g. [1, 61, 111, 141] → blocks {1:60, 61:110, 111:140}
            %            Pass [] to defer — blocks are empty until rebuilt via initReducer.
            mdlObj.MDL.modelID     = modelID;
            mdlObj.MDL.nComponents = nComponents;
            mdlObj.MDL.ax.binEdges = [];
            mdlObj.MDL.ax.block    = {};
            mdlObj.MDL.models      = {};
            if nargin >= 3 && ~isempty(binEdges)
                mdlObj.setBlocks(binEdges);
            end
        end

        function setBlocks(mdlObj, binEdges)
            % Rebuild block index cells and model instances from a new binEdges vector.
            % Safe to call at any time — replaces previous block structure.
            % nCompActual(i) = min(nComponents, numel(block_i)) so that blocks
            % with fewer channels than the requested component count are handled.
            binEdges    = binEdges(:);   % ensure column
            n           = numel(binEdges) - 1;
            blocks      = cell(1, n);
            modelFcn    = str2func(sprintf("model_%s", mdlObj.MDL.modelID));
            models      = cell(1, n);
            nCompActual = zeros(1, n);
            for i = 1:n
                if i < n
                    blocks{i} = binEdges(i) : binEdges(i+1) - 1;                    
                else
                    blocks{i} = binEdges(i) : binEdges(i+1);   % last block closed
                end            
                nCompActual(i) = min(mdlObj.MDL.nComponents, numel(blocks{i}));                               
                models{i}      = modelFcn(nCompActual(i));
            end
            mdlObj.MDL.ax.binEdges    = binEdges;
            mdlObj.MDL.ax.block       = blocks;
            mdlObj.MDL.ax.nCompActual = nCompActual;   % actual per-block output dim
            mdlObj.MDL.models         = models;
        end

        function fit(mdlObj, DM)
            % Fit each block model in place.  No return value.
            % DM : (T x n_features) MATLAB double
            np = py.importlib.import_module('numpy');
            blocks = mdlObj.MDL.ax.block;
            for i = 1:numel(blocks)
                X_block_py = np.array(DM(:, blocks{i}));
                mdlObj.MDL.models{i}.fit(X_block_py);
            end
        end

        function DM_dr = transform(mdlObj, DM)
            % Project DM through each fitted block model.
            % DM  : (T x n_features) MATLAB double
            % Out : (T x sum(nComponents_per_block)) MATLAB double
            np = py.importlib.import_module('numpy');
            blocks = mdlObj.MDL.ax.block;
            out = cell(1, numel(blocks));
            for i = 1:numel(blocks)
                X_block_py = np.array(DM(:, blocks{i}));
                out{i} = double(mdlObj.MDL.models{i}.transform(X_block_py));
            end
            DM_dr = cat(2, out{:});
        end

        function DM_dr = fit_transform(mdlObj, DM)
            % Use native fit_transform if the model exposes it (single-pass,
            % more efficient for sklearn estimators); otherwise fit then transform.
            np = py.importlib.import_module('numpy');
            blocks = mdlObj.MDL.ax.block;
            out = cell(1, numel(blocks));
            for i = 1:numel(blocks)
                try
                    X_block_py = np.array(DM(:, blocks{i}));
                catch
                    keyboard
                end
                if py.hasattr(mdlObj.MDL.models{i}, 'fit_transform')
                    out{i} = double(mdlObj.MDL.models{i}.fit_transform(X_block_py));
                else
                    mdlObj.MDL.models{i}.fit(X_block_py);
                    out{i} = double(mdlObj.MDL.models{i}.transform(X_block_py));
                end
            end
            DM_dr = cat(2, out{:});
        end

    end

end
