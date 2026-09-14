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
            % mdlObj.cfg.fitCfg = nex_generateCfgObj(str2func("nexFit_pca"));
            % Base mdlObject constructor already builds cfg.fitCfg (from
            % modelID) AND the figure — reassigning it here after the fact
            % orphans whatever cfgObj instance the fitCfg panel's spinner
            % callbacks captured at figure-build time. UI edits would keep
            % updating the orphaned original while mdlObj.cfg.fitCfg points
            % at this fresh, still-default instance, so a value entered in
            % the panel would silently never reach fit(). See mdlObj_ssm.m,
            % which already carries this fix (same line, commented out).
            % Headless construction skips nexFigure_pca (which calls setupDomain
            % to build the Domain bus), so do it here in that case. Interactive
            % builds run inside nexFigure_pca during the base constructor.
            isHeadless = isfield(mdlObj.nexon, 'settings') && ...
                         isfield(mdlObj.nexon.settings, 'headless') && ...
                         mdlObj.nexon.settings.headless;
            if isHeadless
                mdlObj.setupDomain();
            end
            % classID = "ssm";
            % mdlObj.model = model_ssm();                        
            % network, etc.
        end

        function setupDomain(mdlObj)
            % Narrow FTR to a single feature axis (D2(1), e.g. 'unit'); the
            % residual axis (e.g. 'measure') is then governed by the Domain MSR
            % selector (default 'rate'). Builds collector.Domain (incl. REG)
            % via initDomainBus, plus Pointer and View (SRC/VW/CLR) buses —
            % same bundling as mdlObj_lda's setupDomain, so headless
            % construction gets the full bus set without depending on the
            % interactive figure to build them piecemeal.
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

        function getDesignMatrix(mdlObj)
            % Build the base (stack) design matrix, then drop the singleton
            % residual axis left by an MSR single-value collapse (e.g.
            % measure -> 'rate') so the fit sees a 2D (samples x feature)
            % matrix. A multi-value MSR selection keeps the residual dim for
            % future slice-looping (dormant).
            getDesignMatrix@mdlObject(mdlObj);
            if ~isempty(mdlObj.DM)
                mdlObj.DM = squeeze(mdlObj.DM);
            end
        end

        function saveFit(mdlObj, uniqueID)
            if nargin < 2 || isempty(uniqueID)
                uniqueID = char(datetime("now", "Format", "yyyyMMdd_HHmmss"));
            end
            try
                [h5Dir, ~, ~] = fileparts(char(mdlObj.nexon.console.BASE.DTS.h5_path(1)));
            catch
                h5Dir = pwd;
            end
            fitDir = fullfile(h5Dir, sprintf('mdlObj_pca_%s', uniqueID));
            if ~exist(fitDir, 'dir'), mkdir(fitDir); end
            pickle = py.importlib.import_module('pickle');
            fid = py.open(fullfile(fitDir, 'model.pkl'), 'wb');
            pickle.dump(mdlObj.model, fid); fid.close();
            fid = py.open(fullfile(fitDir, 'scaler.pkl'), 'wb');
            pickle.dump(mdlObj.Scaler.model, fid); fid.close();
            if isstruct(mdlObj.Reducer) && isfield(mdlObj.Reducer, 'model') ...
                    && ~isempty(mdlObj.Reducer.model)
                fid = py.open(fullfile(fitDir, 'reducer.pkl'), 'wb');
                pickle.dump(mdlObj.Reducer.model, fid); fid.close();
            end
            % Persist fitSentinel (the canonical REG set this fit established,
            % if REG was in use — see nexOp_alignCoAxes/CoRegistration_Design.md
            % "Inference-Time Projection") so loadFit can restore it for a
            % headless/reloaded model's transform() calls.
            fitSentinel = mdlObj.fitSentinel; %#ok<NASGU>
            save(fullfile(fitDir, 'pca_state.mat'), 'fitSentinel');
            mdlObj.fitPath = fitDir;
            fprintf('[mdlObj_pca] saved: %s\n', fitDir);
        end

        function loadFit(mdlObj, fitDir)
            if nargin < 2 || isempty(fitDir)
                fitDir = uigetdir(pwd, "Select PCA fit folder");
                if isequal(fitDir, 0), return; end
            end
            pickle = py.importlib.import_module('pickle');
            fid = py.open(fullfile(fitDir, 'model.pkl'), 'rb');
            mdlObj.model = pickle.load(fid); fid.close();
            fid = py.open(fullfile(fitDir, 'scaler.pkl'), 'rb');
            mdlObj.Scaler.model = pickle.load(fid); fid.close();
            reducerPath = fullfile(fitDir, 'reducer.pkl');
            if exist(reducerPath, 'file')
                if isempty(mdlObj.Reducer), mdlObj.Reducer = struct(); end
                fid = py.open(reducerPath, 'rb');
                mdlObj.Reducer.model = pickle.load(fid); fid.close();
            end
            statePath = fullfile(fitDir, 'pca_state.mat');
            if exist(statePath, 'file')
                S = load(statePath, 'fitSentinel');
                if isfield(S, 'fitSentinel') && ~isempty(S.fitSentinel)
                    mdlObj.fitSentinel = S.fitSentinel;
                end
            end
            mdlObj.fitPath = fitDir;
            fprintf('[mdlObj_pca] loaded: %s\n', fitDir);
        end

        function DF_Z = transform(mdlObj, DF_X)
            % Use learned weights to project emission into state-space
            disp("transforming pca...");
            % DF_X arrives already projected onto the fit-time canonical REG
            % set (scaleApply_transform does this via mdlObj.fitSentinel
            % before calling transform), so the feature width here already
            % matches the scaler/PCA — no separate remap needed. It WILL
            % still carry NaN, though: nexOp_alignCoAxes deliberately
            % NaN-fills canonical positions this specific trial has no real
            % data for (this trial's own recording is, by nature, a partial
            % sample of the full canonical set) — sklearn's transform
            % rejects NaN outright, so it must be zero-filled here, same as
            % getDesignMatrix does on the fit side.
            X = DF_X.df;
            X(isnan(X)) = 0;
            % chanCond = [1:10]; % TEMP            
            % tCond = [1600:2250]; % TEMP
            if ~isempty(X)
                % X = X(:,chanCond);
                % Loop over the 3rd dimension (e.g. spk 'measure'), transforming
                % each 2D (samples x feature) slice independently. size(X,3)
                % returns 1 for a 2D DF, so this degenerates to a single slice
                % and cat(3, ...) below leaves the result 2D — no phantom
                % trailing dimension when fewer than 3 dims exist.
                nSlices  = size(X, 3);
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
                DF_Z.df = Z;
                % PCA replaced the feature axis with 'latent', so emit a CLEAN
                % output ax: keep only axes that remain real dimensions of Z —
                % time (dim 1) and latent (dim 2), plus the looped residual
                % (e.g. measure, dim 3) when present. Dropping the reduced feature
                % axis (unit / chans) stops it lingering as a stale axis; 'latent'
                % is also the reserved DR keyword buildSTATE's G_DF loop skips.
                DN = char(mdlObj.domain.DN(1));
                DF_Z.ax = struct();
                DF_Z.ax.(DN)   = DF_X.ax.(DN);
                DF_Z.ax.latent = [1:size(Z,2)];
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
    end
end