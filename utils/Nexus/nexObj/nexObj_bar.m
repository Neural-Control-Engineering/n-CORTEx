classdef nexObj_bar < nexObject
% Nested bar-chart viewer for mdlObject CV results (nexAnalysis_cvPermute
% output — a STAT-shaped table, one row per CTG combo).
%
%   CTG (multi-select, ordered) — which grouping columns nest the bars,
%       outer-to-inner in selection order. Drives nexStat_binSTAT.
%   VW  (multi-select) — which row values to include at all (same
%       row-filter role VW plays elsewhere — see filterResultsByVW).
%   Pointer — windows any axis OTHER than fold/perm (e.g. t, unit) to a
%       single value; fold is always aggregated into the bar (mean ± SEM),
%       perm always becomes a null-distribution reference band (mean /
%       95th percentile), never individually selected.
%
% Usage:
%   viewer = nexObj_bar(mdlObj)   % wired to an mdlObj source
%   viewer = nexObj_bar(nexon)    % standalone with nexon for colours
%   viewer = nexObj_bar()         % fully standalone (no colour registry)
%   viewer.push('cv_1', R)        % add / update a result (R = STAT-shaped table)

    properties
        source   % mdlObj this viewer watches; may be empty
    end

    methods
        function obj = nexObj_bar(source, headline)
            if nargin < 1 || isempty(source), source = []; end
            if nargin < 2 || isempty(headline), headline = 'Bar Viewer'; end

            % Resolve nexon from source
            if isempty(source)
                nexon_ = [];
            elseif isprop(source, 'nexon') || isfield(source, 'nexon')
                nexon_ = source.nexon;
            elseif isa(source, 'Nexon')
                nexon_ = source; source = [];
            else
                nexon_ = [];
            end

            obj = obj@nexObject(nexon_, [], "", headline);
            obj.classID = "bar";

            % No DTS pull — seed empty DF_postOp
            obj.DF_postOp = struct('df', [], 'ax', struct(), 'ptr', struct());
            obj.domain    = struct('D1', string.empty, 'D2', string.empty, ...
                                   'axes', string.empty, 'F', "", 'animate', "");

            % View bus: SRC = result IDs, CTG = ordered nesting columns,
            % VW = row filter (unique values across CTG columns), CLR = empty
            viewDict.SRC = "";
            viewDict.CTG = "";
            viewDict.VW  = "";
            viewDict.CLR = "";
            obj.collector.View = nexInit_collectorView(obj, viewDict);

            obj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_bar"));

            % Wire to source and register STUBS for its existing results —
            % same lazy pattern as nexObject.discoverResults()/applySRC:
            % RESULTS.(id) = [] populates the SRC list immediately (cheap —
            % just names), the real table is pulled from the live source
            % only when that key is actually selected (see applySRC below).
            % A cvPermute RESULTS table can be a genuinely large N-D score
            % array (nFolds × (1+nPermute) × nTime × nSWP), and a source
            % mdlObj can accumulate several of these over a session — eager
            % deep-copying every one of them here (the old behavior) is
            % real, avoidable startup cost when only one is ever shown
            % first.
            if ~isempty(source) && ~isa(source, 'Nexon')
                obj.source = source;
                if ~isstruct(source.Partners), source.Partners = struct(); end
                source.Partners.viewer = obj;
                if isstruct(source.RESULTS) && ~isempty(fieldnames(source.RESULTS))
                    ids = string(fieldnames(source.RESULTS))';
                    for i = 1:numel(ids)
                        obj.RESULTS.(ids(i)) = [];
                    end
                end
            end

            isHeadless = ~isempty(nexon_) && isfield(nexon_, 'settings') && ...
                         isfield(nexon_.settings, 'headless') && nexon_.settings.headless;
            if ~isHeadless
                nexFigure_bar(obj);
                if isstruct(obj.RESULTS) && ~isempty(fieldnames(obj.RESULTS))
                    obj.refreshSRC();
                end
            end
        end

        function push(obj, resultID, R)
        % Add / update a result and refresh the SRC panel.
            obj.RESULTS.(resultID) = R;
            obj.refreshSRC();
        end

        function refreshSRC(obj)
        % Override: list only RESULTS keys — no "DF" / "DTS" base entry.
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
        % Update SRC selection; forge DF_postOp from the result table's
        % shared per-row axis layout, MINUS fold/perm (those are always
        % aggregated — see class header — never individually
        % Pointer-windowed); rebuild CTG/VW/Pointer; visualize.
            if ~isfield(obj.RESULTS, srcKey), return; end

            % Lazy-load stub on first selection — mirrors nexObject's own
            % discoverResults()/applySRC stub convention, sourced from the
            % live mdlObj instead of nexRESULTS.h5 (see constructor comment).
            % try/catch guards against obj.source having been deleted since
            % the stub was registered — isvalid() alone isn't enough since
            % property access on an already-deleted handle throws.
            if isempty(obj.RESULTS.(srcKey))
                try
                    if isempty(obj.source) || ~isvalid(obj.source) ...
                            || ~isfield(obj.source.RESULTS, srcKey)
                        return;   % source gone, or result no longer there
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
            if ~istable(R) || height(R) == 0, return; end

            ax0      = R.ax{1};
            axFields = setdiff(fieldnames(ax0), {'fold', 'perm'}, 'stable');
            ptrAx    = struct();
            for i = 1:numel(axFields)
                ptrAx.(axFields{i}) = ax0.(axFields{i});
            end
            obj.DF_postOp = struct('df', [], 'ax', ptrAx, 'ptr', struct());
            try
                obj.DF_postOp = nex_initAxisPointer_v2(obj.DF_postOp);
            catch
            end
            obj.domain = obj.inferDomain();
            obj.initPointerBus();
            obj.rebuildPointerPanel();

            % Seed ax--<field> CLR options from this result's own axis
            % fields — mirrors nexObject.initCollectorView's own ax--
            % seeding, which nexObj_bar doesn't call (its CTG/VW come from
            % the RESULTS table's own columns, not a categorical
            % selectionBus, so the rest of that method doesn't fit here).
            % refreshCLR() below only PRESERVES existing ax-- keys across
            % refreshes — it never adds new ones — so this has to run
            % before it. Selecting one only actually colors a bar when the
            % axis name is also a real column on R (true for the CTG
            % columns and for nexVisualization_bar's own expand-axis
            % column); resolveGroupColors silently skips any other ax--key.
            bus.selKeys.CLR = union(bus.selKeys.CLR, "ax--" + string(axFields)', 'stable');

            obj.refreshCTG_bar(R);
            obj.refreshVW();
            obj.refreshCLR();   % base method — scans every RESULTS table's
                                 % own columns; fully generic, no override needed

            obj.visualize();
        end

        function refreshCTG_bar(obj, R)
        % Populate CTG with this result table's own grouping columns, in
        % table-column order — nexObj_bar has no categorical Parent to
        % source CTG from (unlike mdlObject's own refreshCTG). CTG
        % selection order directly drives nexStat_binSTAT's nesting order
        % (outer tier first). All columns selected by default.
            if ~isfield(obj.collector, 'View'), return; end
            bus       = obj.collector.View;
            structCols = ["df","ax","ptr","avgCfg","cov","sem","labels","fitSentinel"];
            cols      = string(R.Properties.VariableNames)';
            groupCols = cols(~ismember(cols, structCols))';
            bus.selKeys.CTG    = groupCols;
            bus.selections.CTG = 1:numel(groupCols);
            if isfield(bus.listBoxes, 'CTG') && ~isempty(bus.listBoxes.CTG) ...
                    && isvalid(bus.listBoxes.CTG)
                bus.listBoxes.CTG.String = cellstr(groupCols);
                bus.listBoxes.CTG.Max    = max(1, numel(groupCols));
                bus.listBoxes.CTG.Value  = 1:numel(groupCols);
            end
        end

        function rebuildPointerPanel(obj)
        % Delete and rebuild pointer controls inside the stored container panel.
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
            nexVisualization_bar(obj, obj.cfg.visCfg.entryParams);
        end
    end
end
