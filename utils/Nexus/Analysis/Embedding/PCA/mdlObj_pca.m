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
            % selector (default 'rate'). Builds collector.Domain via initDomainBus.
            if isfield(mdlObj.domain, 'D2') && numel(mdlObj.domain.D2) >= 1
                mdlObj.domain.FTR = mdlObj.domain.D2(1);
            end
            mdlObj.initDomainBus();
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

        function [STAT, idxSel, drop] = compileSTAT(mdlObj)
            % Compile STAT, then remap each trial's ragged per-unit features onto
            % the fixed canonical channel axis so the PCA feature dimension is
            % stable across sessions/subjects (nexOp_unitsToChannels).
            [STAT, idxSel, drop] = compileSTAT@mdlObject(mdlObj);
            mdlObj.STAT = mdlObj.mapSTAT_unitsToChannels(mdlObj.STAT);
            STAT = mdlObj.STAT;
        end

        function STAT = mapSTAT_unitsToChannels(mdlObj, STAT)
            % Map every STAT trial (t x unit x measure) onto the canonical
            % channel axis. After compileSTAT the ax/ptr are shared across rows,
            % so map a reference DF once for the new channel-space ax/ptr, then
            % remap each row's df with the original per-unit ax.
            if isempty(STAT) || ~all(ismember({'df','ax','ptr'}, ...
                    STAT.Properties.VariableNames))
                return;
            end
            ax0 = STAT.ax(1);
            if ~isstruct(ax0) || ~isfield(ax0, 'unit') || ~isfield(ax0, 'chans')
                return;   % not per-unit spk data — leave unchanged
            end
            canon = mdlObj.resolveCanonicalChans(ax0.chans);
            agg   = mdlObj.chanAggMode();
            ptr0  = STAT.ptr(1);

            DF0m = nexOp_unitsToChannels(struct('df', STAT.df{1}, 'ax', ax0, ...
                                                'ptr', ptr0), canon, agg);
            STAT.df  = cellfun(@(df) mdlObj.mapDF_df(df, ax0, ptr0, canon, agg), ...
                               STAT.df, 'UniformOutput', false);
            STAT.ax  = repmat(DF0m.ax,  height(STAT), 1);
            STAT.ptr = repmat(DF0m.ptr, height(STAT), 1);
        end

        function DF = mapUnitsToChannels_DF(mdlObj, DF)
            % Single-DF map (transform path). No-op if already channel-space.
            if ~isstruct(DF) || ~isfield(DF, 'ax') || ...
                    ~isfield(DF.ax, 'unit') || ~isfield(DF.ax, 'chans')
                return;
            end
            canon = mdlObj.resolveCanonicalChans(DF.ax.chans);
            DF = nexOp_unitsToChannels(DF, canon, mdlObj.chanAggMode());
        end

        function dfc = mapDF_df(~, df, ax, ptr, canon, agg)
            % Map one df array (given its per-unit ax/ptr) -> channel-space df.
            DFm = nexOp_unitsToChannels(struct('df', df, 'ax', ax, 'ptr', ptr), ...
                                        canon, agg);
            dfc = DFm.df;
        end

        function canon = resolveCanonicalChans(mdlObj, chansPerUnit)
            % Fixed canonical channel axis, resolved ONCE (at first fit) and
            % reused for every transform so widths always match. Defaults to a
            % contiguous 1:max(observed channel); set
            % mdlObj.UserData.canonicalChans = (1:nProbeChan)' before fitting for
            % full-probe invariance across subjects.
            if ~isstruct(mdlObj.UserData), mdlObj.UserData = struct(); end
            canon = [];
            if isfield(mdlObj.UserData, 'canonicalChans')
                canon = mdlObj.UserData.canonicalChans;
            end
            if isempty(canon)
                m = max(double(chansPerUnit(:)));
                if isempty(m) || ~isfinite(m)
                    canon = unique(double(chansPerUnit(:)));
                else
                    canon = (1:m)';
                end
                mdlObj.UserData.canonicalChans = canon;
            end
        end

        function m = chanAggMode(mdlObj)
            % Aggregation for units sharing a channel — default "sum".
            m = "sum";
            if isstruct(mdlObj.UserData) && isfield(mdlObj.UserData, 'chanAgg') ...
                    && ~isempty(mdlObj.UserData.chanAgg)
                m = string(mdlObj.UserData.chanAgg);
            end
        end

        function DF_Z = transform(mdlObj, DF_X)
            % Use learned weights to project emission into state-space
            disp("transforming pca...");
            % Map ragged per-unit features onto the fixed canonical channel axis
            % established at fit, so the feature width matches the scaler/PCA.
            DF_X = mdlObj.mapUnitsToChannels_DF(DF_X);
            X = DF_X.df;
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
                D1 = char(mdlObj.domain.D1);
                DF_Z.ax = struct();
                DF_Z.ax.(D1)   = DF_X.ax.(D1);
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