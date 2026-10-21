classdef nexObj_violin < nexObject
% nexObj_violin  Per-cell trial-level distribution viewer. Two entry
% points feed the same rendering core (nexVisualization_violin.m) --
% DESIGN.md ("Mixed-Effects Modeling" doc) section 4:
%
%   nexObj_violin(mdlObj)   -- mdlObj-sourced, e.g. off a live mdlObj_lme.
%       RESULTS rows are combos (one per domain.CTG combo), each carrying
%       a df/ax p-value grid AND a T_long long-format table (the raw
%       trial-level data that grid's p-values were computed from). This
%       viewer reads T_long, not df/ax -- the p-value grid is what
%       nexObj_monoGram visualizes off the SAME RESULTS row instead.
%   nexObj_violin(ctg)      -- ctg-sourced ("pure analysis/visualization"),
%       off a categorical Parent directly, same as any other nexObject.
%       compileAndVisualize() compiles its own STAT via nexOp_compileSTAT
%       and builds one long table via buildLongSTAT, stored as a single
%       RESULTS entry ("live") and fed through the identical applySRC/
%       visualize path as the mdlObj-sourced case above.
%
% Rendering (nexVisualization_violin.m): CTG-selected columns + multi-
% select Pointer axes ("expand axes") split one long table into violin
% groups -- same nexStat_binSTAT + expand-axis mechanism
% nexVisualization_bar.m already uses for bars, just drawing a
% KDE+scatter+error group per resulting position instead of one bar
% height. Persistent handles (array, grown as the group count changes),
% not cla()+rebuild -- see ensureViolinHandles in nexVisualization_violin.m.
%
% Usage:
%   viewer = nexObj_violin(mdlObj)       % mdlObj-sourced
%   viewer = nexObj_violin(ctg)          % ctg-sourced (standalone)
%   viewer = nexObj_violin()             % fully standalone (no colour registry)
%   viewer.push('chainFit1', R)          % add/update a result (mdlObj-sourced path)

    properties
    end

    methods
        function obj = nexObj_violin(source, headline)
            if nargin < 1 || isempty(source), source = []; end
            if nargin < 2 || isempty(headline), headline = 'Violin'; end

            % MATLAB disallows a conditionalized superclass constructor
            % call (same constraint nexObj_monoGram.m's own header comment
            % flags) -- resolve args for BOTH possible branches first,
            % call obj@nexObject(...) exactly once, unconditionally, then
            % branch for the rest of setup. mdlObj-sourced passes Parent=[]
            % to the superclass (source isn't a categorical Parent); ctg-
            % sourced passes the categorical hub itself.
            isMdlSource = ~isempty(source) && isa(source, 'mdlObject');
            [nexon_, source_] = nexObject.resolveNexonFromSource(source);
            if isMdlSource
                superParent = [];
            else
                superParent = source_;
            end
            obj = obj@nexObject(nexon_, superParent, "", headline);
            obj.classID = "violin";

            % Shared setup, both entry points -- no DTS pull either way
            % (mdlObj-sourced has no DF to pull; ctg-sourced's actual data
            % only exists once compileAndVisualize() runs, see there).
            obj.DF_postOp = struct('df', [], 'ax', struct(), 'ptr', struct());
            obj.domain    = struct('D1', string.empty, 'D2', string.empty, ...
                                   'axes', string.empty, 'F', "", 'animate', "");
            obj.pMap      = struct();

            viewDict.SRC = "";
            viewDict.CTG = "";
            viewDict.VW  = "";
            viewDict.CLR = "";
            obj.collector.View = nexInit_collectorView(obj, viewDict);

            obj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_violin"));

            if isMdlSource
                obj.wireModelSource(source_);
            end

            isHeadless = ~isempty(nexon_) && isfield(nexon_, 'settings') && ...
                         isfield(nexon_.settings, 'headless') && nexon_.settings.headless;
            if ~isHeadless
                nexFigure_violin(obj);
                if isMdlSource && isstruct(obj.RESULTS) && ~isempty(fieldnames(obj.RESULTS))
                    obj.refreshSRC();
                end
            end
        end

        function compileAndVisualize(obj, gridCols)
        % ctg-sourced path only -- compiles STAT off obj.Parent's current
        % categories/items selection (same nexOp_compileSTAT free function
        % mdlObject.compileSTAT() wraps -- confirmed generic over both
        % object families), builds one long table via buildLongSTAT (no
        % Target/quantization concept here -- targetInfo = []), and
        % stores it as a single "live" RESULTS entry through the exact
        % same applySRC/visualize path the mdlObj-sourced branch uses.
        % selectedCTGCols (from the View panel's own CTG listbox, read
        % fresh here since CTG itself is populated FROM T0's columns only
        % after this compile runs -- a chicken/egg the mdlObj-sourced path
        % doesn't have, since there CTG options exist the moment a
        % RESULTS row is selected) is not a parameter: compileAndVisualize
        % always pulls every real STAT category column as a long-table
        % column (gridCols narrows which become GRID dimensions vs.
        % grouping columns is a CTG/Pointer-bus choice made AFTER this
        % compiles, not before).
            if nargin < 2, gridCols = {}; end
            if isempty(obj.Parent) || ~isvalid(obj.Parent)
                fprintf('[nexObj_violin] compileAndVisualize: no categorical Parent to compile from.\n');
                return;
            end
            [STAT, ~, ~] = nexOp_compileSTAT(obj, obj.dfID_source, ...
                obj.Parent.selectionBus.categories, obj.Parent.selectionBus.items, [], []);
            if isempty(STAT) || height(STAT) == 0
                fprintf('[nexObj_violin] compileAndVisualize: compileSTAT returned no rows.\n');
                return;
            end
            obj.STAT = STAT;
            allCols  = setdiff(string(STAT.Properties.VariableNames), ["df","ax","ptr"], 'stable');
            T_long   = buildLongSTAT(STAT, allCols, gridCols, []);
            obj.RESULTS.live = table({[]}, {struct()}, {[]}, {T_long}, ...
                'VariableNames', {'df', 'ax', 'ptr', 'T_long'});
            obj.refreshSRC();
        end

        function push(obj, resultID, R)
        % Add/update a result and refresh the SRC panel -- mdlObj-sourced
        % path (mirrors nexObj_bar.push verbatim).
            obj.RESULTS.(resultID) = R;
            obj.refreshSRC();
        end

        function refreshSRC(obj)
        % Override: list only RESULTS keys -- no "DF"/"DTS" base entry
        % (mirrors nexObj_bar.refreshSRC verbatim).
            if ~isfield(obj.collector, 'View'), return; end
            bus  = obj.collector.View;
            keys = string(fieldnames(obj.RESULTS))';
            nK   = numel(keys);
            bus.selKeys.SRC    = keys;
            bus.selections.SRC = nK;
            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                    && isvalid(bus.listBoxes.SRC)
                bus.listBoxes.SRC.String = cellstr(keys);
                bus.listBoxes.SRC.Max    = 1;
                bus.listBoxes.SRC.Value  = max(1, nK);
            end
            if nK > 0
                obj.applySRC(char(keys(end)));
            end
        end

        function applySRC(obj, srcKey)
        % Update SRC selection; forge DF_postOp.ax from T_long's OWN real
        % columns (NOT R.ax{row}, which is the p-value grid's axes --
        % violin visualizes the raw distribution, a different shape
        % entirely -- see class header); rebuild CTG/VW/Pointer; visualize.
            if ~isfield(obj.RESULTS, srcKey), return; end

            % Lazy-load stub on first selection -- mirrors nexObj_bar's
            % own convention (mdlObj-sourced path only; obj.source is
            % empty for the ctg-sourced path, so this is a no-op there).
            if isempty(obj.RESULTS.(srcKey))
                try
                    if isempty(obj.source) || ~isvalid(obj.source) ...
                            || ~isfield(obj.source.RESULTS, srcKey)
                        return;
                    end
                    obj.RESULTS.(srcKey) = obj.source.RESULTS.(srcKey);
                catch
                    return;
                end
            end

            bus = obj.collector.View;
            idx = find(string(bus.selKeys.SRC) == string(srcKey), 1);
            if ~isempty(idx)
                bus.selections.SRC = idx;
                if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                        && isvalid(bus.listBoxes.SRC)
                    bus.listBoxes.SRC.Value = idx;
                end
            end

            R = obj.RESULTS.(srcKey);
            if ~istable(R) || height(R) == 0 || ~ismember('T_long', R.Properties.VariableNames)
                return;
            end
            T0 = R.T_long{1};
            if ~istable(T0) || height(T0) == 0, return; end

            % "trial" is a row IDENTIFIER (buildLongSTAT's own broadcast
            % key), not a measurement axis -- it must never become a
            % Pointer/collapse axis. nexVisualization_violin's "collapse
            % every non-grouping column to its Pointer selection" step
            % would otherwise narrow T down to ONE specific trial by
            % default (buildSelection's initSel=1 convention), on top of
            % every other uncollapsed column also narrowing to its own
            % single default value simultaneously -- confirmed directly:
            % picking chans as the only CTG column still produced zero
            % surviving rows (silent clearViolins) because trial AND
            % h5_responseThreshold_g AND sessionLabel_subj AND t AND f
            % each collapsed to one arbitrary value at once, an
            % intersection that's essentially always empty.
            axFields = setdiff(string(T0.Properties.VariableNames), ["df", "trial"], 'stable');
            ptrAx = struct();
            for i = 1:numel(axFields)
                f = char(axFields(i));
                v = T0.(f);
                if iscategorical(v), v = categories(v); end
                ptrAx.(f) = unique(v);
            end
            obj.DF_postOp = struct('df', [], 'ax', ptrAx, 'ptr', struct());
            try
                obj.DF_postOp = nex_initAxisPointer_v2(obj.DF_postOp);
            catch
            end
            obj.domain = obj.inferDomain();
            isFirstBuild = ~isfield(obj.collector, 'Pointer') || isempty(obj.collector.Pointer);
            if isFirstBuild
                obj.initPointerBus();
                % Every axis the violin collapses by default should start
                % at "select all" (aggregate over it), not buildSelection's
                % shared initSel=1 convention (one arbitrary value) --
                % the distribution-across-everything-not-grouped-by IS the
                % point of a violin plot. The user can narrow a specific
                % axis afterward via the Pointer panel if they want to
                % window into one band/time/etc. Only on first build --
                % refreshPointerAxes_ (the else branch) deliberately
                % preserves whatever the user already narrowed across a
                % later SRC switch.
                for i = 1:numel(axFields)
                    f = char(axFields(i));
                    if isfield(obj.collector.Pointer.selections, f)
                        obj.collector.Pointer.selections.(f) = 1:numel(obj.collector.Pointer.selKeys.(f));
                        if isfield(obj.collector.Pointer.listBoxes, f) ...
                                && ~isempty(obj.collector.Pointer.listBoxes.(f)) ...
                                && isvalid(obj.collector.Pointer.listBoxes.(f))
                            obj.collector.Pointer.listBoxes.(f).Value = obj.collector.Pointer.selections.(f);
                        end
                    end
                end
            else
                obj.refreshPointerAxes_(ptrAx);
            end
            obj.rebuildPointerPanel();

            bus.selKeys.CLR = union(bus.selKeys.CLR, "ax--" + axFields', 'stable');

            obj.refreshCTG_violin(T0);
            obj.refreshVW();
            obj.refreshCLR();

            obj.visualize();
        end

        function refreshCTG_violin(obj, T0)
        % Populate CTG with T0's own real columns (minus df) -- no
        % categorical Parent to source CTG from on the mdlObj-sourced
        % path; the ctg-sourced path COULD read Parent.selectionBus.categories
        % instead (same as the base nexObject.refreshCTG), but T0's own
        % columns are already exactly the right candidate set for either
        % path, so one mechanism covers both. Nothing selected by default
        % -- violin grouping is an explicit user choice, not "everything".
            if ~isfield(obj.collector, 'View'), return; end
            bus       = obj.collector.View;
            groupCols = setdiff(string(T0.Properties.VariableNames), "df", 'stable')';
            bus.selKeys.CTG    = groupCols;
            bus.selections.CTG = [];
            if isfield(bus.listBoxes, 'CTG') && ~isempty(bus.listBoxes.CTG) ...
                    && isvalid(bus.listBoxes.CTG)
                bus.listBoxes.CTG.String = cellstr(groupCols);
                bus.listBoxes.CTG.Max    = max(1, numel(groupCols));
                bus.listBoxes.CTG.Value  = [];
            end
        end

        function rebuildPointerPanel(obj)
        % Delete and rebuild pointer controls inside the stored container
        % panel (mirrors nexObj_bar.rebuildPointerPanel verbatim).
            if ~isfield(obj.Figure, 'ptrContainer'), return; end
            ph = obj.Figure.ptrContainer;
            if isempty(ph) || ~isvalid(ph), return; end
            delete(ph.Children);
            if isempty(obj.collector.Pointer) || isempty(obj.nexon), return; end
            try
                nexObj_listCfgPanel(obj.nexon, struct('ph', ph), ...
                    obj.collector.Pointer, []);
            catch
            end
        end

        function visualize(obj)
            nexVisualization_violin(obj, obj.cfg.visCfg.entryParams);
        end
    end
end
