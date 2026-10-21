classdef mdlObj_cebra < mdlObject

    properties        
    end

    methods
        function obj = mdlObj_cebra(Parent, Origin, dfID_source, predictorID, headline)
            % cebra = py.importlib.import_module('cebra');
            % args = extractMethodCfg('model_cebra');
            % % neural network handle to train and infer from a neural
            % mdlObj.modelObj = model_cebra(cebra, args);
            if nargin < 4, predictorID = []; end
            if nargin < 5, headline = []; end
            obj = obj@mdlObject(Parent, Origin, "cebra", dfID_source, predictorID, headline);            
            obj.py.np = py.importlib.import_module('numpy');
            sklearnPreProc = py.importlib.import_module('sklearn.preprocessing'); 
            obj.py.stdScaler = sklearnPreProc.StandardScaler();            
            % obj.cfg.fitCfg = nex_generateCfgObj(str2func("nexFit_cebra"));
            % Base mdlObject constructor already builds cfg.fitCfg (from
            % modelID) AND the figure — reassigning it here orphans whatever
            % cfgObj instance the fitCfg panel's spinner callbacks captured
            % at figure-build time, so UI edits would silently never reach
            % fit(). See mdlObj_ssm.m / mdlObj_pca.m.
            obj.cfg.dmCfg.format="cebra";
            % network, etc.
            % Headless construction skips nexFigure_cebra (which calls
            % setupDomain to build the Domain bus), so do it here in that
            % case. Interactive builds run inside nexFigure_cebra during
            % the base constructor — same split as mdlObj_pca/mdlObj_ssm.
            % isfield() never works on objects (handle or dynamicprops),
            % only plain structs -- isprop() is correct here; .settings
            % itself IS a plain struct, so isfield() on it stays correct.
            isHeadless = isprop(obj.nexon, 'settings') && ...
                         isfield(obj.nexon.settings, 'headless') && ...
                         obj.nexon.settings.headless;
            if isHeadless
                obj.setupDomain();
            end
        end

        function setupDomain(mdlObj)
            % Narrow FTR to a single feature axis (D2(1), e.g. 'unit'); the
            % residual axis (e.g. 'measure') is then governed by the Domain
            % MSR selector. Builds collector.Domain (incl. REG) via
            % initDomainBus, plus Pointer and View (SRC/VW/CLR) buses —
            % same bundling as mdlObj_pca/mdlObj_lda's own setupDomain, so
            % headless construction gets the full bus set without depending
            % on the interactive figure to build them piecemeal.
            if isfield(mdlObj.domain, 'D2') && numel(mdlObj.domain.D2) >= 1
                mdlObj.domain.FTR = mdlObj.domain.D2(1);
            end
            mdlObj.initDomainBus();
            mdlObj.initPointerBus();
            mdlObj.initViewBus();
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
        %     dnSel=mdlObj.domain.DN(1);
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
            % Use learned weights to project emission into state-space.
            % Mirrors mdlObj_pca.transform's own robustness fixes: NaN-fill
            % (nexOp_alignCoAxes deliberately NaN-pads canonical positions
            % this trial has no real data for; sklearn's/CEBRA's transform
            % rejects NaN outright), loop over a residual MSR slice when
            % present (size(X,3)==1 degenerates to a single pass, so this
            % is a no-op for the common 2D case), and a clean output ax
            % (only the axes that remain real dimensions of Z survive).
            disp("transforming cebra...");
            X = DF_X.df;
            X(isnan(X)) = 0;
            if ~isempty(X)
                nSlices  = size(X, 3);
                Z_slices = cell(1, nSlices);
                for k = 1:nSlices
                    X_k      = X(:, :, k);
                    X_k_py   = mdlObj.py.np.array(X_k);
                    X_scaled = mdlObj.py.stdScaler.transform(X_k_py);
                    Z_k      = double(mdlObj.model.transform(X_scaled));
                    Z_slices{k} = Z_k;
                end
                Z = cat(3, Z_slices{:});
                DF_Z.df = Z;
                DN = char(mdlObj.domain.DN(1));
                DF_Z.ax = struct();
                DF_Z.ax.(DN)   = DF_X.ax.(DN);
                DF_Z.ax.latent = 1:size(Z, 2);
                if ndims(Z) >= 3
                    ra = "";
                    try, ra = char(mdlObj.domain.MSRaxis); catch, end
                    if strlength(ra) > 0 && isfield(DF_X.ax, ra)
                        DF_Z.ax.(ra) = DF_X.ax.(ra);
                    end
                end
                DF_Z = nex_initAxisPointer_v2(DF_Z);
            else
                DF_Z = [];
            end
        end

        function saveFit(mdlObj, uniqueID)
            [h5Dir, ~, ~] = fileparts(char(mdlObj.nexon.console.BASE.DTS.h5_path(1)));
            fitDir = fullfile(h5Dir, sprintf('mdlObj_cebra_%s', uniqueID));
            if ~exist(fitDir, 'dir'), mkdir(fitDir); end
            mdlObj.fitPath = fitDir;
            pickle = py.importlib.import_module('pickle');
            fid = py.open(fullfile(fitDir, 'model.pkl'), 'wb');
            pickle.dump(mdlObj.model, fid); fid.close();
            fid = py.open(fullfile(fitDir, 'scaler.pkl'), 'wb');
            pickle.dump(mdlObj.py.stdScaler, fid); fid.close();
        end

        function loadFit(mdlObj, fitDir)
            mdlObj.fitPath = fitDir;
            pickle = py.importlib.import_module('pickle');
            fid    = py.open(fullfile(fitDir, 'model.pkl'), 'rb');
            mdlObj.model = pickle.load(fid); fid.close();
            fid    = py.open(fullfile(fitDir, 'scaler.pkl'), 'rb');
            mdlObj.py.stdScaler = pickle.load(fid); fid.close();
        end
    end
end