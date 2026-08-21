classdef nexObj_stateSpace < nexObject

    properties
        STATE = [];
        AVG   = []         % table: rows = group averages; cols = df (cell) + grouping label(s)        
    end

    methods

        % ── Constructor ───────────────────────────────────────────────────
        function nexObj = nexObj_stateSpace(nexon, Parent, Partner, dfID_source, headline)
            % dfID_source : optional — if provided, DF is loaded from DTS and
            %               used to seed domain/ptr axes. If empty, axes are
            %               inherited from Partner.DF_postOp where available.
            if nargin < 4, dfID_source = []; end
            if nargin < 5, headline = []; end

            nexObj = nexObj@nexObject(nexon, Parent, dfID_source, headline);
            nexObj.Origin=nexObj.Parent;
            nexObj.classID = "stspc";

            %% Partner
            if ~isempty(Partner)
                partnerID = Partner.classID;
                nexObj.Partners.(partnerID) = Partner;
                nexObj.STAT = Partner.STAT;
            end

            %% STAT — inherit from categorical Parent if available
            % nexOp_compileSTAT is too expensive to call at construction;
            % categorical already holds a compiled STAT from reportStats().
            if ~isempty(nexObj.Parent) && strcmp(nexObj.Parent.classID, 'ctg')
                S_categories = nex_returnSelectionMask(nexObj.Parent.selectionBus.categories);
                S_items = nex_returnSelectionMask(nexObj.Parent.selectionBus.items);
                % nexObj.STAT = nexOp_compileSTAT(nexObj.Parent, nexObj.dfID_source, S_categories, S_items, []);
                nexObj.STAT = nexOp_compileSTAT(nexObj, nexObj.dfID_source, S_categories, S_items, []);
            end

            %% Config
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_stateSpace"));
            nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexObject.stepAnimate"));

            %% DF — for domain / ptr axis seeding only (not STATE source)
            if ~isempty(dfID_source)
                nexObj.DF = dtsIO_readDF(nexObj.nexon, dfID_source, []);
                % Fallback: global read may return empty when transform is partial.
                if isempty(nexObj.DF) || ~isfield(nexObj.DF, 'df') || isempty(nexObj.DF.df)
                    sentinelRow = dtsIO_findSentinelRow(nexObj.nexon, dfID_source);
                    if ~isempty(sentinelRow)
                        nexObj.DF = dtsIO_readDF(nexObj.nexon, dfID_source, sentinelRow);
                        fprintf('[nexObj_stateSpace] partial transform — sentinel row %d: %s\n', ...
                            sentinelRow, nexObj.nexon.console.BASE.DTS.sessionLabel{sentinelRow});
                    end
                end
            elseif ~isempty(Partner) && ~isempty(Partner.DF_postOp)
                nexObj.DF = Partner.DF_postOp;
            end

            if ~isempty(nexObj.DF)
                nexObj.DF_postOp = nexObj.DF;
                % nexObj.DF_postOp = nex_initAxisPointer_v2(nexObj.DF_postOp);
                nexObj.DF_postOp.ptr = nexInit_axisPointer(nexObj.DF_postOp.df, nexObj.DF_postOp.ax);
                nexObj.DF_postOp = nexObj_DF(nexObj.DF_postOp);
            end

            %% Pool map
            try
                nexObj.pMap = nexInit_pMap(nexObj, nexObj.DF_postOp);
            catch e
                disp(getReport(e));
            end

            %% Domain
            nexObj.domain = nexObj.inferDomain();

            %% Collector — View selection bus
            % AVG: STAT columns suitable for group-by (exclude DF structural fields)
            DF_STRUCT_FIELDS = ["df", "ax", "ptr", "avgCfg"];
            if ~isempty(nexObj.STAT) && istable(nexObj.STAT)
                allCols = string(nexObj.STAT.Properties.VariableNames)';
                avgKeys = allCols(~ismember(allCols, DF_STRUCT_FIELDS));
                if isempty(avgKeys), avgKeys = ""; end
            else
                avgKeys = "";
            end
            % VW: group name values from nexObj.AVG (empty at construction;
            %     refreshed via refreshVW() after reportAverage populates AVG)
            vwKeys = nexObj.getCTGGroupKeys();
            % CLR: non-DF STAT columns available for colorization (same pool as CTG).
            %      Empty if STAT does not yet exist.
            clrKeys = avgKeys;
            viewDict.CTG = avgKeys;
            viewDict.VW  = vwKeys;
            viewDict.CLR = clrKeys;
            nexObj.collector.View = nexInit_collectorView(nexObj, viewDict);

            %% Collector — Domain selection bus (F / D1 / ANI)
            % F: values inside DF.ax.latent — the actual latent labels (pc1, pc2,
            %    x1, x2, ...) produced by PCA, SSM, CEBRA, etc.  'latent' is the
            %    reserved ax keyword for dimensionality-reduction outputs.
            %    Empty if DF has no ax.latent field.
            % D1 / ANI: DF.ax field names — the axis dimensions available for
            %    primary and animated axis selection.  'latent' is excluded as
            %    it is reserved for the F sub-bus.
            if ~isempty(nexObj.domain.axes)
                axisKeys = nexObj.domain.axes;
                axisKeys = axisKeys(~strcmp(axisKeys, "latent"));
                if isempty(axisKeys), axisKeys = ""; end
            else
                axisKeys = "";
            end
            if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax') ...
                    && isfield(nexObj.DF_postOp.ax, 'latent')
                fKeys = nexObj.DF_postOp.ax.latent;
            else
                fKeys = "";
            end
            domainDict.F   = fKeys;
            domainDict.D1  = axisKeys;
            domainDict.ANI = axisKeys;
            nexObj.collector.Domain = buildSelection(nexObj, domainDict);

            %% Collector — Pointer selection bus (one key per DF.ax dimension)
            % Candidate values are the actual axis values (human-readable).
            % Selecting a value on a non-animated axis pins the trajectory to
            % that slice. The animated axis's effective value is driven by
            % domain.animate / STATE.ptr — its Pointer selection sets the
            % starting position only.
            if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax') ...
                    && ~isempty(nexObj.DF_postOp.ax)
                axFields = fieldnames(nexObj.DF_postOp.ax);
                axFields = axFields(~strcmp(axFields, 'latent'));
                ptrDict  = struct();
                for i = 1:numel(axFields)
                    axDim = nexObj.DF_postOp.ptr.(axFields{i}).dim;
                    if ~isempty(axDim)
                        ptrDict.(axFields{i}) = nexObj.DF_postOp.ax.(axFields{i});
                    end
                end
                if ~isempty(fieldnames(ptrDict))
                    nexObj.collector.Pointer = buildSelection(nexObj, ptrDict);
                else
                    nexObj.collector.Pointer = [];
                end
            else
                nexObj.collector.Pointer = [];
            end

            % Listener: when pooling changes DF_postOp.ax, refresh Pointer bus.
            % Mirrors the nexObj_categorical pattern (nexOp_sBus_alignItems2ax).
            if ~isempty(nexObj.collector.Pointer) && ~isempty(nexObj.DF_postOp) ...
                    && isa(nexObj.DF_postOp, 'nexObj_DF')
                addlistener(nexObj.DF_postOp, 'ax', 'PostSet', ...
                    @(~,~) nexObj.refreshPointer());
            end

            % Seed initial D1 / ANI selections to match current domain state
            if ~isempty(nexObj.domain.D1) && ~isequal(nexObj.domain.D1, "")
                d1Idx = find(ismember(axisKeys, nexObj.domain.D1(1)), 1);
                if ~isempty(d1Idx)
                    nexObj.collector.Domain.selections.D1 = d1Idx;
                end
            end
            if ~isempty(nexObj.domain.animate) && ~isequal(nexObj.domain.animate, "")
                aniIdx = find(ismember(axisKeys, nexObj.domain.animate), 1);
                if ~isempty(aniIdx)
                    nexObj.collector.Domain.selections.ANI = aniIdx;
                end
            end

            %% Figure
            nexFigure_stateSpace(nexObj);
            nexObj.refreshSRC();    % populate SRC listbox with "DF" + "STAT" immediately

            % Discover previously saved results on disk (stubs load lazily on selection)
            try
                if ismember('h5_path', nexObj.nexon.console.BASE.DTS.Properties.VariableNames)
                    nexObj.discoverResults();
                end
            catch
            end

            %% Player
            nexObj.player = timer('Period', 0.1, 'BusyMode', 'drop', ...
                'ExecutionMode', 'fixedRate', ...
                'TimerFcn', @(~,~) nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams));
        end

        % ── Player ────────────────────────────────────────────────────────
        % function startPlayer(nexObj)
        %     isPlay = nexObj.Figure.playButton.Value;
        %     switch isPlay
        %         case 0, nexObj.player.start;
        %         case 1, nexObj.player.stop;
        %     end
        % end

        % ── Animation ─────────────────────────────────────────────────────
        % function stepAnimate(nexObj, args)
        %     % CFG HEADER
        %     stride = args.stride; % default = 1
        %     % Guard: STATE must be built before animation is meaningful
        %     if isempty(nexObj.STATE) || ~isfield(nexObj.STATE, 'ptr')
        %         return;
        %     end
        %     axSel = char(nexObj.domain.animate);
        %     if ~isprop(nexObj.STATE.ptr, axSel), return; end
        %     r    = nexObj.STATE.ptr.(axSel).range;
        %     span = r(2) - r(1) + 1;
        %     nexObj.STATE.ptr.(axSel).value = r(1) + mod(nexObj.STATE.ptr.(axSel).value - r(1) + stride, span);
        %     % D1 pan vs D2 sweep: both advance value; visualization
        %     % reads .window to decide how much of Z to render (pan = window
        %     % subset; sweep = single slice matched against G).
        %     nexObj.visualize();
        % end

        % ── Core pipeline ─────────────────────────────────────────────────
        function visualize(nexObj)
            visArgs = nexObj.cfg.visCfg.entryParams;
            nexVisualization_stateSpace(nexObj, visArgs);
        end

        function updateScope(nexObj)
            % Apply pooling to DF_postOp, then re-visualize from cached STATE.
            % Writing DF_postOp.ax triggers the PostSet listener → refreshPointer().
            if ~isempty(nexObj.pMap) && ~isempty(nexObj.DF) ...
                    && ~isempty(nexObj.DF_postOp)
                try
                    ptr = nexObj.DF_postOp.ptr;
                    DF_pooled = nexOp_poolAxes(nexObj.pMap, nexObj.DF, ptr);
                    nexObj.DF_postOp.df = DF_pooled.df;
                    nexObj.DF_postOp.ax = DF_pooled.ax;   % triggers PostSet → refreshPointer()
                catch e
                    disp(getReport(e));
                end
            end
            if ~isempty(nexObj.STATE)
                nexObj.visualize();
            end
        end

        function refreshPointer(nexObj)
            % Three-field update of Pointer selectionBus when DF_postOp.ax changes.
            % Only resets selections when axis values actually changed — preserves
            % user selections when pooling fires PostSet without changing content.
            if isempty(nexObj.collector.Pointer), return; end
            bus = nexObj.collector.Pointer;
            axFields = fieldnames(nexObj.DF_postOp.ax);
            axFields = axFields(~strcmp(axFields, 'latent'));
            for i = 1:numel(axFields)
                ax = axFields{i};
                if ~isfield(bus.selKeys, ax), continue; end
                newVals = nexObj.DF_postOp.ax.(ax);
                oldVals = bus.selKeys.(ax);
                if isequal(newVals, oldVals), continue; end   % axis unchanged — preserve selection
                nVals  = numel(newVals);
                % Map selection by value range: find new indices whose values
                % fall within [min, max] of the previously selected values.
                curSel    = bus.selections.(ax);
                validSel  = curSel(curSel >= 1 & curSel <= numel(oldVals));
                if ~isempty(validSel) && isnumeric(oldVals)
                    selRange = oldVals(validSel);
                    newSel   = find(newVals >= min(selRange) & newVals <= max(selRange));
                else
                    newSel   = [];
                end
                if isempty(newSel), newSel = 1:nVals; end   % fallback to all
                bus.selKeys.(ax)    = newVals;
                bus.selections.(ax) = newSel;
                if isfield(bus.listBoxes, ax) && ~isempty(bus.listBoxes.(ax))
                    bus.listBoxes.(ax).String = newVals;
                    bus.listBoxes.(ax).Max    = nVals;
                    bus.listBoxes.(ax).Value  = newSel;
                end
            end
        end

        % ── STATE construction ────────────────────────────────────────────
        function buildSTATE(nexObj)
            % Build STATE for every selected SRC and concatenate — supports overlay.
            % Expensive — called explicitly via UI button or applySRC, not on every update.
            bus     = nexObj.collector.View;
            selIdx  = bus.selections.SRC;
            srcKeys = string(bus.selKeys.SRC(selIdx));

            Z_all = {}; S_all = {}; G_all = {};
            for ki = 1:numel(srcKeys)
                src = char(srcKeys(ki));
                % Lazy-load disk stubs on first selection.
                if isfield(nexObj.RESULTS, src) && isempty(nexObj.RESULTS.(src))
                    try, nexObj.loadResult(src); catch, continue; end
                end
                switch src
                    case 'DF',   ST = nexObj.buildSTATE_fromDF();
                    case 'STAT', ST = nexObj.buildSTATE_fromSTAT();
                    otherwise
                        if isfield(nexObj.RESULTS, src)
                            ST = nexObj.buildSTATE_fromRESULT(src);
                        else, continue; end
                end
                if isempty(ST) || ~isfield(ST,'Z') || isempty(ST.Z), continue; end
                G_src = ST.G;
                if numel(srcKeys) > 1
                    G_src.SRC = repmat(string(src), height(G_src), 1);
                end
                Z_all{end+1} = ST.Z; %#ok<AGROW>
                S_all{end+1} = ST.S; %#ok<AGROW>
                G_all{end+1} = G_src; %#ok<AGROW>
            end

            if isempty(Z_all), nexObj.STATE = struct(); return; end

            % Align G column sets before vertcat (sources may have different metadata).
            if numel(G_all) > 1
                colSets = cellfun(@(t) string(t.Properties.VariableNames), G_all, 'UniformOutput', false);
                allCols = unique(horzcat(colSets{:}), 'stable');
                for ki = 1:numel(G_all)
                    miss = allCols(~ismember(allCols, string(G_all{ki}.Properties.VariableNames)));
                    for ci = 1:numel(miss)
                        G_all{ki}.(char(miss(ci))) = repmat("", height(G_all{ki}), 1);
                    end
                end
            end

            STATE.Z = cat(1, Z_all{:});
            STATE.S = cat(1, S_all{:});
            STATE.G = vertcat(G_all{:});
            STATE   = nexObj.finalizeSTATEptr(STATE);
            nexObj.STATE = STATE;
            if isfield(STATE,'Z') && ~isempty(STATE.Z)
                nexObj.visualize();
            end
        end

        function STATE = buildSTATE_fromDF(nexObj)
            % Single router trial — lightweight, good for online/in-situ exploration.
            STATE = struct();
            DF = dtsIO_readDF(nexObj.nexon, nexObj.dfID_source, []);
            if isempty(DF) || ~isfield(DF, 'df') || isempty(DF.df)
                if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'df')
                    DF = struct('df', nexObj.DF_postOp.df);
                else
                    return;
                end
            end
            Z       = DF.df;
            T       = size(Z, 1);
            STATE.Z = Z;
            STATE.S = zeros(size(Z));
            STATE.G = table((1:T)', 'VariableNames', {'sampleNumber'});
            STATE   = nexObj.finalizeSTATEptr(STATE);
        end

        function STATE = buildSTATE_fromSTAT(nexObj)
            % All selected trials — multi-trial scatter / trajectory overlay.
            STATE = struct();
            STAT = nexObj.STAT;
            if isempty(STAT) || ~istable(STAT) || ~ismember('df', STAT.Properties.VariableNames)
                return;
            end
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","sem","cov","labels"];
            metaCols = setdiff(string(STAT.Properties.VariableNames), DF_STRUCT_FIELDS);

            Z_parts = {}; G_parts = {};
            for r = 1:height(STAT)
                df_r = STAT.df{r};
                if isempty(df_r), continue; end
                if isstruct(df_r) && isfield(df_r, 'df'), df_r = df_r.df; end
                T_r = size(df_r, 1);
                G_r = table((1:T_r)', 'VariableNames', {'sampleNumber'});
                if ismember('ax', STAT.Properties.VariableNames) && ~isempty(STAT.ax{r})
                    axS = STAT.ax{r};
                    if isstruct(axS)
                        for axFn = string(fieldnames(axS))'
                            axVals = double(axS.(char(axFn))(:));
                            if numel(axVals) == T_r
                                G_r.(char(axFn)) = axVals;
                            end
                        end
                    end
                end
                for ci = 1:numel(metaCols)
                    col = char(metaCols(ci));
                    try
                        val = STAT.(col)(r);
                        if iscell(val), val = val{1}; end
                        G_r.(col) = repmat(string(val), T_r, 1);
                    catch, end
                end
                Z_parts{end+1} = df_r;   %#ok<AGROW>
                G_parts{end+1} = G_r;    %#ok<AGROW>
            end
            if isempty(Z_parts), return; end
            STATE.Z = cat(1, Z_parts{:});
            STATE.S = zeros(size(STATE.Z));
            STATE.G = vertcat(G_parts{:});
            STATE   = nexObj.finalizeSTATEptr(STATE);
        end

        function STATE = buildSTATE_fromRESULT(nexObj, key)
            % Group averages with SEM from a stored RESULTS entry.
            STATE = struct();
            RESULT = nexObj.RESULTS.(key);
            if isempty(RESULT) || ~istable(RESULT), return; end
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","sem","cov","labels"];
            metaCols = setdiff(string(RESULT.Properties.VariableNames), DF_STRUCT_FIELDS);
            hasSEM   = ismember('sem', RESULT.Properties.VariableNames);

            Z_parts = {}; S_parts = {}; G_parts = {};
            for g = 1:height(RESULT)
                df_g = RESULT.df{g};
                if isempty(df_g), continue; end
                T_g   = size(df_g, 1);
                sem_g = zeros(size(df_g));
                if hasSEM && ~isempty(RESULT.sem{g}), sem_g = RESULT.sem{g}; end
                G_g = table((1:T_g)', 'VariableNames', {'sampleNumber'});
                % Propagate axis values into G so the visualizer can use
                % physical coordinates (e.g. ax.t for the animate window).
                if ismember('ax', RESULT.Properties.VariableNames) && ~isempty(RESULT.ax{g})
                    axS = RESULT.ax{g};
                    if isstruct(axS)
                        for axFn = string(fieldnames(axS))'
                            axVals = double(axS.(char(axFn))(:));
                            if numel(axVals) == T_g
                                G_g.(char(axFn)) = axVals;
                            end
                        end
                    end
                end
                for ci = 1:numel(metaCols)
                    col = char(metaCols(ci));
                    try
                        val = RESULT.(col)(g);
                        if iscell(val), val = val{1}; end
                        G_g.(col) = repmat(string(val), T_g, 1);
                    catch, end
                end
                Z_parts{end+1} = df_g;   %#ok<AGROW>
                S_parts{end+1} = sem_g;  %#ok<AGROW>
                G_parts{end+1} = G_g;    %#ok<AGROW>
            end
            if isempty(Z_parts), return; end
            STATE.Z = cat(1, Z_parts{:});
            STATE.S = cat(1, S_parts{:});
            STATE.G = vertcat(G_parts{:});
            STATE   = nexObj.finalizeSTATEptr(STATE);
        end

        function STATE = finalizeSTATEptr(nexObj, STATE)
            % Build sampleNumber ptr and refresh domain.F — shared by all sub-builders.
            if ~isfield(STATE, 'G') || isempty(STATE.G) || height(STATE.G) == 0, return; end
            T = max(STATE.G.sampleNumber);
            sPtr.sampleNumber.dim    = 1;
            sPtr.sampleNumber.value  = 1;
            sPtr.sampleNumber.range  = [1, T];
            sPtr.sampleNumber.window = T;
            STATE.ptr = nexObj_ptr(sPtr);
            if ~isempty(STATE.Z)
                nF = size(STATE.Z, 2);
                if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax') ...
                        && isfield(nexObj.DF_postOp.ax, 'latent')
                    nexObj.domain.F = string(nexObj.DF_postOp.ax.latent);
                elseif isempty(nexObj.domain.F) || isequal(nexObj.domain.F, "")
                    nexObj.domain.F = "f" + string(1:nF);
                end
                nexObj.refreshDomainF(nexObj.domain.F);
            end
        end

        % ── Existing methods (preserved) ──────────────────────────────────
        function joinSamplesByGroup(nexObj)
            % groupIDCols resolved from View.CTG selectionBus
            nexObj.STAT = nexObj.Partners.ctg.STAT;
            viewSel = nex_returnSelectionMask(nexObj.collector.View);
            groupIDCols = viewSel.CTG;
            nexObj.STAT = nexOp_fuseGroups(nexObj.STAT, groupIDCols);
        end

        function reportAverage(nexObj, resultID, nBins, STAT)
            % Delegate to base class (grouping, binning, RESULTS store, bus refresh),
            % then rebuild STATE for the newly selected result.
            if nargin < 2, resultID = []; end
            if nargin < 3, nBins    = []; end
            if nargin < 4, STAT     = []; end
            reportAverage@nexObject(nexObj, resultID, nBins, STAT);
            % Base class refreshSRC auto-selects the newest result; rebuild STATE for it.
            src = nexObj.getCurrentSRC();
            if ~ismember(src, {'DF','STAT'}) && isfield(nexObj.RESULTS, src) ...
                    && ~isempty(nexObj.RESULTS.(src))
                nexObj.buildSTATE();
            end
        end

        function reportAverage_legacy(nexObj)
            STAT = nexObj.STAT;
            % dfCol = nexOp_trimDfCol(STAT.df);
            TF = table2struct(STAT); TF = arrayfun(@(DF) DF, TF, "UniformOutput", false);
            TF_aligned = nexOp_eventAlignTF(nexObj, TF);
            [dfCol, axCol] = nexOp_trimTF(TF);
            STAT.df = dfCol(:);
            STAT.ax = repmat(axCol, height(STAT),1);
            viewSel  = nex_returnSelectionMask(nexObj.collector.View);
            groupCol = char(viewSel.CTG);
            [G, groupNames] = findgroups(STAT.(groupCol));
            catDim = ndims(dfCol{1}) + 1;
            STAT_avg = splitapply(@(tf) {mean(cat(catDim, tf{:}), catDim)}, STAT.df, G);
            AVG.df = STAT_avg;
            AVG.(groupCol) = groupNames;
            T_AVG = struct2table(AVG);
            % preserve ax and ptr from the averaged data itself
            if ismember('ax', STAT.Properties.VariableNames) && ~isempty(STAT.ax(1))
                ax_ref    = STAT.ax(1);
                T_AVG.ax  = repmat({ax_ref}, height(T_AVG), 1);
                T_AVG.ptr = repmat({nexInit_axisPointer(STAT_avg(1), ax_ref)}, height(T_AVG), 1);

                % Trim DF_postOp to match the AVG coordinate space, then
                % assign ax to fire PostSet → refreshPointer() automatically.
                if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'df') ...
                        && isprop(nexObj.DF_postOp, 'ptr') && ~isempty(nexObj.DF_postOp.ptr)
                    df_trim  = nexObj.DF_postOp.df;
                    axFields = fieldnames(ax_ref);
                    for fi = 1:numel(axFields)
                        f      = axFields{fi};
                        newLen = numel(ax_ref.(f));
                        if isprop(nexObj.DF_postOp.ptr, f)
                            dim    = nexObj.DF_postOp.ptr.(f).dim;
                            curLen = size(df_trim, dim);
                            if newLen < curLen
                                idx      = repmat({':'}, 1, ndims(df_trim));
                                idx{dim} = 1:newLen;
                                df_trim  = df_trim(idx{:});
                            end
                        end
                    end
                    nexObj.DF_postOp.df = df_trim;
                    nexObj.DF_postOp.ax = ax_ref;   % PostSet fires refreshPointer()
                end
            end

            nexObj.AVG = T_AVG;
            nexObj.refreshVW();
        end

        % ── View bus helpers ───────────────────────────────────────────────
        function refreshSRC(nexObj)
            % Override: stateSpace always exposes "DF" and "STAT" as base options.
            if ~isfield(nexObj.collector, 'View'), return; end
            bus      = nexObj.collector.View;
            baseKeys = ["DF"; "STAT"];
            keys     = [baseKeys; string(fieldnames(nexObj.RESULTS))];
            labels   = keys;
            for ki = numel(baseKeys)+1:numel(keys)
                k = char(keys(ki));
                if isfield(nexObj.resultLabels, k)
                    labels(ki) = string(nexObj.resultLabels.(k));
                end
            end
            % Auto-select the newest result when RESULTS is non-empty; else default to "DF".
            if ~isempty(fieldnames(nexObj.RESULTS))
                newSel = numel(keys);
            else
                newSel = 1;
            end
            bus.selKeys.SRC    = keys;
            bus.selections.SRC = newSel;
            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC)
                bus.listBoxes.SRC.String = labels;
                bus.listBoxes.SRC.Max    = numel(keys);   % multi-select enabled
                bus.listBoxes.SRC.Value  = newSel;
            end
        end

        function onSRCChanged(nexObj, lb)
            % Multi-select aware: sync all selected indices then rebuild STATE.
            nexObj.collector.View.selections.SRC = lb.Value;
            % AVG mirrors the last selected RESULT (drives VW label lookup in vis).
            srcKeys = string(nexObj.collector.View.selKeys.SRC(lb.Value));
            lastKey = char(srcKeys(end));
            if ~ismember(lastKey, {'DF','STAT'}) && isfield(nexObj.RESULTS, lastKey)
                nexObj.AVG = nexObj.RESULTS.(lastKey);
            else
                nexObj.AVG = [];
            end
            nexObj.refreshVW();
            nexObj.buildSTATE();
        end

        function applySRC(nexObj, srcKey)
            % Sync AVG mirror (used by visualization), lazy-load disk stubs,
            % update SRC bus index, refresh VW, then rebuild STATE.
            if ~isfield(nexObj.collector, 'View'), return; end
            % Lazy-load disk stubs on first selection (delegates to base class).
            if isfield(nexObj.RESULTS, srcKey) && isempty(nexObj.RESULTS.(srcKey))
                try, nexObj.loadResult(srcKey); catch, return; end
            end
            % Update SRC bus selection index and listbox.
            bus = nexObj.collector.View;
            idx = find(string(bus.selKeys.SRC) == string(srcKey), 1);
            if ~isempty(idx)
                bus.selections.SRC = idx;
                if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC)
                    bus.listBoxes.SRC.Value = idx;
                end
            end
            % Sync AVG mirror for visualization.
            switch srcKey
                case {'DF', 'STAT'}
                    nexObj.AVG = [];
                otherwise
                    if isfield(nexObj.RESULTS, srcKey)
                        nexObj.AVG = nexObj.RESULTS.(srcKey);
                    else
                        return;
                    end
            end
            nexObj.refreshVW();
            nexObj.buildSTATE();
        end

        function refreshVW(nexObj)
            % Base class handles VW bus update (preserving prior selections);
            % stateSpace adds tracker handle rebuild when group set changes.
            refreshVW@nexObject(nexObj);
            nexObj.rebuildTrackers();
        end

        function rebuildTrackers(nexObj)
            % Structural tier: create/delete canvas_tracker scatter handles to match
            % the current VW selection. NEVER call from visualize() or stepAnimate() —
            % handle operations are too slow for the animation hot path.
            % visualize() only does set() on handles that already exist here.
            if ~isfield(nexObj.Figure, 'panel0'), return; end
            gfx = nexObj.Figure.panel0.tiles.graphics;
            ax  = nexObj.Figure.panel0.tiles.ax;

            % Current VW group set
            viewSel   = nex_returnSelectionMask(nexObj.collector.View);
            activeGrps = string(viewSel.VW);
            if isequal(activeGrps, ""), activeGrps = string.empty; end

            % Sanitize group labels → valid MATLAB identifiers for struct field names.
            % The raw label is preserved in activeGrps; activeFlds holds the safe name.
            % matlab.lang.makeValidName handles digits-first, punctuation, spaces, etc.
            if isempty(activeGrps)
                activeFlds = string.empty;
            else
                activeFlds = string(matlab.lang.makeValidName(cellstr(activeGrps)));
            end

            % Remove handles for groups no longer in VW
            existing = string(fieldnames(gfx.canvas_tracker))';
            for fld = existing
                if ~ismember(fld, activeFlds)
                    if isvalid(gfx.canvas_tracker.(fld))
                        delete(gfx.canvas_tracker.(fld));
                    end
                    gfx.canvas_tracker = rmfield(gfx.canvas_tracker, fld);
                end
            end

            % Create handles for groups newly added to VW
            hold(ax, "on");
            for i = 1:numel(activeGrps)
                fld = char(activeFlds(i));
                if ~isfield(gfx.canvas_tracker, fld) || ~isvalid(gfx.canvas_tracker.(fld))
                    gfx.canvas_tracker.(fld) = scatter3(ax, [], [], [], ...
                        150, nexObj.nexon.settings.Colors.cyberGreen, ...
                        "filled", "MarkerFaceAlpha", 0.9);
                end
            end
            hold(ax, "off");

            % Write back (struct is value-type inside the Figure struct)
            nexObj.Figure.panel0.tiles.graphics.canvas_tracker = gfx.canvas_tracker;

            %% Legend proxies — one NaN-positioned plot3 per VW group.
            % Created/deleted here; colors are updated each frame by visualize().
            GREEN = nexObj.nexon.settings.Colors.cyberGreen;
            if ~isfield(gfx, 'legend_proxies')
                gfx.legend_proxies = struct();
            end

            existingLP = string(fieldnames(gfx.legend_proxies))';
            for fld = existingLP
                if ~ismember(fld, activeFlds)
                    if isvalid(gfx.legend_proxies.(fld))
                        delete(gfx.legend_proxies.(fld));
                    end
                    gfx.legend_proxies = rmfield(gfx.legend_proxies, fld);
                end
            end

            hold(ax, "on");
            for i = 1:numel(activeGrps)
                fld = char(activeFlds(i));
                lbl = char(activeGrps(i));
                if ~isfield(gfx.legend_proxies, fld) || ~isvalid(gfx.legend_proxies.(fld))
                    gfx.legend_proxies.(fld) = plot3(ax, NaN, NaN, NaN, 'o', ...
                        'Color',           GREEN, ...
                        'MarkerFaceColor', GREEN, ...
                        'MarkerSize',      6, ...
                        'LineStyle',       'none', ...
                        'DisplayName',     lbl);
                else
                    gfx.legend_proxies.(fld).DisplayName = lbl;
                end
            end
            hold(ax, "off");
            nexObj.Figure.panel0.tiles.graphics.legend_proxies = gfx.legend_proxies;

            % Configure legend appearance once (structural rebuild)
            if ~isempty(activeGrps)
                proxyH = gobjects(0);
                for i = 1:numel(activeGrps)
                    fld = char(activeFlds(i));
                    if isfield(gfx.legend_proxies, fld) && isvalid(gfx.legend_proxies.(fld))
                        proxyH(end+1) = gfx.legend_proxies.(fld); %#ok<AGROW>
                    end
                end
                if ~isempty(proxyH)
                    lg = legend(ax, proxyH, ...
                        'TextColor',   GREEN, ...
                        'Color',       [0 0 0], ...
                        'EdgeColor',   GREEN, ...
                        'FontSize',    7, ...
                        'Interpreter', 'none', ...
                        'Location',    'northeast');
                    lg.Box = 'on';
                end
            else
                legend(ax, 'off');
            end
        end

        % ── Domain bus helpers ─────────────────────────────────────────────
        function refreshDomainF(nexObj, fKeys)
            % Full three-field update of F sub-bus after STATE.Z is built.
            if ~isfield(nexObj.collector, 'Domain'), return; end
            bus = nexObj.collector.Domain;
            bus.selKeys.F    = fKeys;
            nF = numel(fKeys);
            bus.selections.F = 1:min(3, nF);   % default first 3 latents
            if isfield(bus.listBoxes, 'F') && ~isempty(bus.listBoxes.F)
                bus.listBoxes.F.Value  = 1:min(3, nF);
                bus.listBoxes.F.String = fKeys;
                bus.listBoxes.F.Max    = 3;  % scatter3 uses exactly X/Y/Z — cap at 3
            end
        end

        function applyDomainBus(nexObj)
            % Read Domain selectionBus and apply to nexObj.domain, then re-visualize.
            % Called by the Refresh button — wires F / D1 / ANI selections into
            % domain.F, domain.D1 (+ inferred D2), and domain.animate.
            % NOTE: F must be applied AFTER inferDomain() because the base-class
            % inferDomain() resets domain.F = string(dfID_source), overwriting
            % any user selection set before the call.
            if ~isfield(nexObj.collector, 'Domain'), return; end
            domSel = nex_returnSelectionMask(nexObj.collector.Domain);
            % D1 — primary axis; D2 inferred as complement via inferDomain
            if ~isequal(domSel.D1, "")
                nexObj.domain.D1 = domSel.D1(:)';
                nexObj.domain    = nexObj.inferDomain();
            end
            % ANI — animated axis; also updates domain.D2 via setAnimateAxis
            if ~isequal(domSel.ANI, "")
                nexObj.setAnimateAxis(char(domSel.ANI));
            end
            % F — applied last so inferDomain() cannot overwrite the user's selection
            if ~isequal(domSel.F, "")
                nexObj.domain.F = domSel.F(:)';
            end
            nexObj.updateScope();
        end

        function filterSTATE(nexObj) %#ok<MANU>
            % Placeholder for future STATE filtering logic.
            % Will apply ptr-driven row selection to nexObj.STATE.
        end

    end
end
