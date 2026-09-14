classdef mdlObj_lda < mdlObject

    properties
    end

    methods
        function mdlObj = mdlObj_lda(Parent, Origin, dfID_source, predictorID, headline)
            if nargin < 4, predictorID = []; end
            if nargin < 5, headline = []; end
            mdlObj = mdlObj@mdlObject(Parent, Origin, "lda", dfID_source, predictorID, headline);
            mdlObj.py.np = py.importlib.import_module('numpy');
            sklearnPreProc = py.importlib.import_module('sklearn.preprocessing');
            mdlObj.Scaler.model = sklearnPreProc.StandardScaler();
            % mdlObj.cfg.fitCfg = nex_generateCfgObj(str2func("nexFit_lda"));
            % Base mdlObject constructor already builds cfg.fitCfg (from
            % modelID) AND the figure — reassigning it here orphans whatever
            % cfgObj instance the fitCfg panel's spinner callbacks captured
            % at figure-build time, so UI edits (e.g. n_components) would
            % silently never reach fit(). See mdlObj_ssm.m / mdlObj_pca.m.
            mdlObj.cfg.dmCfg.format = "supervised";
            mdlObj.initTargetBus();
            isHeadless = isfield(mdlObj.nexon, 'settings') && ...
                         isfield(mdlObj.nexon.settings, 'headless') && ...
                         mdlObj.nexon.settings.headless;
            if isHeadless
                mdlObj.setupDomain();
            end
        end

        function setupDomain(mdlObj)
            if isfield(mdlObj.domain, 'D2') && numel(mdlObj.domain.D2) >= 1
                mdlObj.domain.FTR = mdlObj.domain.D2(1);
            end
            mdlObj.initDomainBus();
            mdlObj.initPointerBus();
            mdlObj.initViewBus();
        end

        function DF_Z = transform(mdlObj, DF_X)
            if isempty(DF_X.df)
                DF_Z = [];
                return;
            end
            X_flat   = mdlObj.flattenInput(DF_X);
            np       = mdlObj.py.np;
            X_py     = np.atleast_2d(np.array(X_flat));
            X_scaled = mdlObj.Scaler.model.transform(X_py);
            Z_py     = np.ascontiguousarray(mdlObj.model.transform(X_scaled));
            Z        = double(Z_py);
            DF_Z.df        = Z;
            DN             = char(mdlObj.domain.DN(1));
            if DN ~= "None"
                DF_Z.ax.(DN) = DF_X.ax.(DN);
            end
            DF_Z.ax.latent = 1:size(Z, 2);
            DF_Z           = nex_initAxisPointer_v2(DF_Z);
        end

        function saveFit(mdlObj, uniqueID)
            [h5Dir, ~, ~] = fileparts(char(mdlObj.nexon.console.BASE.DTS.h5_path(1)));
            fitDir = fullfile(h5Dir, sprintf('mdlObj_lda_%s', uniqueID));
            if ~exist(fitDir, 'dir'), mkdir(fitDir); end
            mdlObj.fitPath = fitDir;
            pickle = py.importlib.import_module('pickle');
            fid = py.open(fullfile(fitDir, 'model.pkl'), 'wb');
            pickle.dump(mdlObj.model, fid); fid.close();
            fid = py.open(fullfile(fitDir, 'scaler.pkl'), 'wb');
            pickle.dump(mdlObj.Scaler.model, fid); fid.close();
        end

        function loadFit(mdlObj, fitDir)
            mdlObj.fitPath = fitDir;
            pickle = py.importlib.import_module('pickle');
            fid    = py.open(fullfile(fitDir, 'model.pkl'), 'rb');
            mdlObj.model = pickle.load(fid); fid.close();
            fid    = py.open(fullfile(fitDir, 'scaler.pkl'), 'rb');
            mdlObj.Scaler.model = pickle.load(fid); fid.close();
        end

        % ── Results lifecycle ─────────────────────────────────────────────
        % Mirrors mdlObj_linear's pattern so RESULTS from nexAnalysis_cvPermute
        % (CTG-combo rows, each with df/ax/ptr/fitSentinel) become browsable via
        % SRC/VW, not just stored. No LDA-specific render-on-VW-selection hook
        % exists yet (mdlObj_linear has nexFigure_linear_renderSRC; LDA doesn't
        % have an equivalent) — this wires up SRC/VW/CLR bookkeeping only.
        % Plotting a selected VW row's accuracy curve is still unbuilt.

        function storeResult(mdlObj, resultID, data)
            mdlObj.RESULTS.(resultID) = data;
            bus = mdlObj.collector.View;
            if ~ismember(resultID, bus.selKeys.SRC)
                bus.selKeys.SRC = [bus.selKeys.SRC, string(resultID)];
                if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                        && isvalid(bus.listBoxes.SRC)
                    bus.listBoxes.SRC.String = cellstr(bus.selKeys.SRC);
                    bus.listBoxes.SRC.Max    = numel(bus.selKeys.SRC);
                end
            end
            mdlObj.applySRC(resultID);
        end

        function applySRC(mdlObj, srcKey)
        % Switch active source. srcKey = 'fit' → clear VW/CLR (current in-memory
        % fit, no comparison rows). srcKey = <resultID> → populate VW/CLR from
        % that RESULTS entry's rows.
            srcKey = char(srcKey);
            isFit  = strcmp(srcKey, 'fit');
            bus    = mdlObj.collector.View;

            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                    && isvalid(bus.listBoxes.SRC)
                idx = find(bus.selKeys.SRC == string(srcKey), 1);
                if ~isempty(idx)
                    bus.listBoxes.SRC.Value = idx;
                    bus.selections.SRC      = idx;
                end
            end

            if isFit
                bus.selKeys.CLR = "";
                bus.selKeys.VW  = "";
                if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW) ...
                        && isvalid(bus.listBoxes.VW)
                    bus.listBoxes.VW.String = {};
                    bus.listBoxes.VW.Value  = [];
                end
                if isfield(bus.listBoxes, 'CLR') && ~isempty(bus.listBoxes.CLR) ...
                        && isvalid(bus.listBoxes.CLR)
                    bus.listBoxes.CLR.String = {};
                    bus.listBoxes.CLR.Value  = [];
                end
            elseif isfield(mdlObj.RESULTS, srcKey)
                mdlObj.refreshVW(srcKey);

                R = mdlObj.RESULTS.(srcKey);
                if istable(R) && ismember('ax', R.Properties.VariableNames)
                    axNames = string(fieldnames(R.ax{1}))';
                    clrOpts = axNames(~ismember(axNames, "perm"));
                elseif isstruct(R) && isfield(R, 'ax')
                    axNames = string(fieldnames(R.ax))';
                    clrOpts = axNames(~ismember(axNames, "perm"));
                else
                    clrOpts = string.empty(1,0);
                end
                if isempty(clrOpts), clrOpts = "fold"; end
                bus.selKeys.CLR    = clrOpts;
                bus.selections.CLR = 1;
                if isfield(bus.listBoxes, 'CLR') && ~isempty(bus.listBoxes.CLR) ...
                        && isvalid(bus.listBoxes.CLR)
                    bus.listBoxes.CLR.String = cellstr(clrOpts);
                    bus.listBoxes.CLR.Max    = numel(clrOpts);
                    bus.listBoxes.CLR.Value  = 1;
                end
            end
        end

        function refreshVW(mdlObj, resultID)
        % Populate the VW listbox from the rows of RESULTS.(resultID) — one
        % row per CTG combo for nexAnalysis_cvPermute output. Row labels are
        % built from non-structural columns (CTG label columns); 'fitSentinel'
        % is excluded alongside df/ax/ptr since it's per-row metadata, not a
        % label to join into the row string.
            if ~isfield(mdlObj.RESULTS, resultID), return; end
            R = mdlObj.RESULTS.(resultID);

            if istable(R)
                structural = ["df","ax","ptr","avgCfg","fitSentinel"];
                groupCols  = setdiff(string(R.Properties.VariableNames), structural, 'stable');
                if isempty(groupCols)
                    rowLabels = arrayfun(@(i) sprintf("row_%d", i), ...
                                        (1:height(R))', 'UniformOutput', false);
                    rowLabels = string(rowLabels);
                else
                    rowLabels = string(R.(char(groupCols(1))));
                    for c = 2:numel(groupCols)
                        rowLabels = rowLabels + " | " + string(R.(char(groupCols(c))));
                    end
                end
            else
                % Plain DF struct — treat as single-row result
                rowLabels = string(resultID);
            end

            bus = mdlObj.collector.View;
            nVW = numel(rowLabels);
            bus.selKeys.VW    = rowLabels;
            bus.selections.VW = 1:nVW;

            if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW) ...
                    && isvalid(bus.listBoxes.VW)
                bus.listBoxes.VW.String = cellstr(rowLabels);
                bus.listBoxes.VW.Max    = nVW;
                bus.listBoxes.VW.Value  = 1:nVW;   % all selected by default
            end
        end
    end
end
