classdef nexObj_stateSpace < nexObject

    properties
        STAT  = [];
        STATE = [];
        AVG   = []         % table: rows = group averages; cols = df (cell) + grouping label(s)        
    end

    methods

        % ── Constructor ───────────────────────────────────────────────────
        function nexObj = nexObj_stateSpace(nexon, Parent, Partner, dfID_source)
            % dfID_source : optional — if provided, DF is loaded from DTS and
            %               used to seed domain/ptr axes. If empty, axes are
            %               inherited from Partner.DF_postOp where available.
            if nargin < 4, dfID_source = []; end

            nexObj = nexObj@nexObject(nexon, Parent, dfID_source);
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
            vwKeys = nexObj.getAVGGroupKeys();
            % CLR: non-DF STAT columns available for colorization (same pool as AVG).
            %      Empty if STAT does not yet exist.
            clrKeys = avgKeys;
            viewDict.AVG = avgKeys;
            viewDict.VW  = vwKeys;
            viewDict.CLR = clrKeys;
            nexObj.collector.View = buildSelection(nexObj, viewDict);

            %% Collector — Domain selection bus (F / D1 / ANI)
            % F: values inside DF.ax.factor — the actual factor labels (pc1, pc2,
            %    x1, x2, ...) produced by PCA, SSM, CEBRA, etc.  'factor' is the
            %    reserved ax keyword for dimensionality-reduction outputs.
            %    Empty if DF has no ax.factor field.
            % D1 / ANI: DF.ax field names — the axis dimensions available for
            %    primary and animated axis selection.  'factor' is excluded as
            %    it is reserved for the F sub-bus.
            if ~isempty(nexObj.domain.axes)
                axisKeys = nexObj.domain.axes;
                axisKeys = axisKeys(~strcmp(axisKeys, "factor"));
                if isempty(axisKeys), axisKeys = ""; end
            else
                axisKeys = "";
            end
            if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax') ...
                    && isfield(nexObj.DF_postOp.ax, 'factor')
                fKeys = nexObj.DF_postOp.ax.factor;
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
                axFields = axFields(~strcmp(axFields, 'factor'));
                for i = 1:numel(axFields)
                    ptrDict.(axFields{i}) = nexObj.DF_postOp.ax.(axFields{i});
                end
                nexObj.collector.Pointer = buildSelection(nexObj, ptrDict);
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

            %% Player
            nexObj.player = timer('Period', 0.2, 'BusyMode', 'drop', ...
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
            axFields = axFields(~strcmp(axFields, 'factor'));
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
            % Compile STAT / AVG / DF into nexObj.STATE and initialize ptr.
            % Expensive — called explicitly via UI button, not on every update.
            STATE = struct();

            %% AVG — pool then stack
            ptr = [];
            if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ptr')
                ptr = nexObj.DF_postOp.ptr;
            end
            try
                AVG_pool = nexOp_poolDF(nexObj.pMap, nexObj.AVG, ptr);
                [Z_AVG, G_AVG, S_AVG] = nexOp_stackSTAT(AVG_pool);
            catch e
                disp(getReport(e));
                Z_AVG = []; G_AVG = []; S_AVG = [];
            end

            %% DF (raw / realtime source)
            % G_DF mirrors the nexOp_stackSTAT output shape: sampleNumber +
            % one column per DF_postOp.ax field (excluding 'factor').
            % No grouping columns — DF rows are a single unlabelled trajectory.
            if ~isempty(nexObj.DF_postOp)
                try
                    Z_DF  = nexObj.DF_postOp.df;
                    T_DF  = size(Z_DF, 1);
                    S_DF  = zeros(size(Z_DF));
                    G_DF  = table((1:T_DF)', 'VariableNames', {'sampleNumber'});
                    if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax')
                        axFields = fieldnames(nexObj.DF_postOp.ax);
                        axFields = axFields(~strcmp(axFields, 'factor'));
                        for k = 1:numel(axFields)
                            f    = axFields{k};
                            vals = nexObj.DF_postOp.ax.(f)';   % transpose to Nx1
                            idx  = min((1:T_DF)', numel(vals));
                            G_DF.(f) = vals(idx);
                        end
                    end
                catch e
                    disp(getReport(e));
                    Z_DF = []; G_DF = []; S_DF = [];
                end
            else
                Z_DF = []; G_DF = []; S_DF = [];
            end

            %% STAT — use STAT's own ptr column, independent of AVG
            % try
            %     ptr_stat = [];
            %     if ~isempty(nexObj.STAT) && istable(nexObj.STAT) ...
            %             && ismember('ptr', nexObj.STAT.Properties.VariableNames) ...
            %             && ~isempty(nexObj.STAT.ptr(1))
            %         ptr_stat = nexObj.STAT.ptr(1);
            %     end
            %     STAT_pool = nexOp_poolDF(nexObj.pMap, nexObj.STAT, ptr_stat);
            %     [Z_STAT, G_STAT, S_STAT] = nexOp_stackSTAT(STAT_pool);
            % catch e
            %     disp(getReport(e));
            %     Z_STAT = []; G_STAT = []; S_STAT = [];
            % end

            STATE.Z = [Z_AVG; Z_DF];
            STATE.S = [S_AVG; S_DF];

            % Impute missing columns in G_DF before vertical concat.
            % G_AVG has grouping columns (e.g. sessionLabel_phase) that G_DF lacks;
            % fill them with NaN (numeric) or {''} (cell/string) so heights match.
            if istable(G_AVG) && istable(G_DF) && ~isempty(G_DF)
                missingCols = setdiff(G_AVG.Properties.VariableNames, ...
                                      G_DF.Properties.VariableNames);
                for c = 1:numel(missingCols)
                    col = missingCols{c};
                    ref = G_AVG.(col);
                    if isnumeric(ref) || islogical(ref)
                        G_DF.(col) = NaN(height(G_DF), 1);
                    else
                        G_DF.(col) = repmat({''}, height(G_DF), 1);
                    end
                end
                G_DF = G_DF(:, G_AVG.Properties.VariableNames);  % match column order
            end
            STATE.G = [G_AVG; G_DF];

            %% STATE ptr — within-group trajectory frame (1..T), not global row.
            % sampleNumber in STATE.G is the per-group row index; the ptr
            % range covers [1, T] so stepAnimate advances all groups in
            % lockstep.  The full stack remains visible on the canvas; the
            % tracker windows on this value per group independently.
            if ~isempty(STATE.G) && height(STATE.G) > 0
                T = max(STATE.G.sampleNumber);
                sPtr.sampleNumber.dim    = 1;
                sPtr.sampleNumber.value  = 1;
                sPtr.sampleNumber.range  = [1, T];
                sPtr.sampleNumber.window = T;   % default: show full trajectory
                STATE.ptr = nexObj_ptr(sPtr);
            end

            nexObj.STATE = STATE;

            %% Auto-populate domain.F from ax.factor labels or column count
            if ~isempty(STATE.Z)
                nFactors = size(STATE.Z, 2);
                if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax') ...
                        && isfield(nexObj.DF_postOp.ax, 'factor')
                    nexObj.domain.F = string(nexObj.DF_postOp.ax.factor);
                elseif isempty(nexObj.domain.F) || isequal(nexObj.domain.F, "")
                    nexObj.domain.F = "f" + string(1:nFactors);
                end
                nexObj.refreshDomainF(nexObj.domain.F);
            end
        end

        % ── Existing methods (preserved) ──────────────────────────────────
        function joinSamplesByGroup(nexObj)
            % groupIDCols resolved from View.AVG selectionBus
            nexObj.STAT = nexObj.Partners.ctg.STAT;
            viewSel = nex_returnSelectionMask(nexObj.collector.View);
            groupIDCols = viewSel.AVG;
            nexObj.STAT = nexOp_fuseGroups(nexObj.STAT, groupIDCols);
        end

        function reportAverage(nexObj)
            STAT = nexObj.STAT;
            % dfCol = nexOp_trimDfCol(STAT.df);
            TF = table2struct(STAT); TF = arrayfun(@(DF) DF, TF, "UniformOutput", false);
            [dfCol, axCol] = nexOp_trimTF(TF);
            STAT.df = dfCol(:);
            STAT.ax = repmat(axCol, height(STAT),1);
            viewSel  = nex_returnSelectionMask(nexObj.collector.View);
            groupCol = char(viewSel.AVG);
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
        function vwKeys = getAVGGroupKeys(nexObj)
            % Return unique group name values from nexObj.AVG table for VW bus.
            DF_STRUCT_FIELDS = ["df", "ax", "ptr", "avgCfg", "cov", "sem", "labels"];
            if isempty(nexObj.AVG) || ~istable(nexObj.AVG)
                vwKeys = "";
                return;
            end
            cols = string(nexObj.AVG.Properties.VariableNames)';
            groupCols = cols(~ismember(cols, DF_STRUCT_FIELDS));
            if isempty(groupCols)
                vwKeys = "";
                return;
            end
            vwKeys = unique(nexObj.AVG.(char(groupCols(1))));
        end

        function refreshVW(nexObj)
            % Full three-field update of VW selectionBus after AVG is populated.
            % Must update selKeys, selection index, AND listbox — updating only
            % selKeys leaves the listbox stale and index potentially out of range.
            % (Pattern from nexOp_sBus_alignItems2ax.)
            if ~isfield(nexObj.collector, 'View'), return; end
            newKeys = nexObj.getAVGGroupKeys();
            bus = nexObj.collector.View;
            nVW = numel(newKeys);
            bus.selKeys.VW    = newKeys;
            bus.selections.VW = 1:nVW;
            if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW)
                bus.listBoxes.VW.String = newKeys;
                bus.listBoxes.VW.Max    = nVW;
                bus.listBoxes.VW.Value  = 1:nVW;
            end
            % VW group membership changed — rebuild tracker handles before next frame.
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

            % Sanitize group labels: hyphens → underscores for use as field names.
            % The raw label (e.g. "L-hind-paw-CCI") is preserved in activeGrps;
            % activeFlds holds the corresponding valid field name.
            activeFlds = strrep(activeGrps, '-', '_');

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
        end

        % ── Domain bus helpers ─────────────────────────────────────────────
        function refreshDomainF(nexObj, fKeys)
            % Full three-field update of F sub-bus after STATE.Z is built.
            if ~isfield(nexObj.collector, 'Domain'), return; end
            bus = nexObj.collector.Domain;
            bus.selKeys.F    = fKeys;
            nF = numel(fKeys);
            bus.selections.F = 1:min(3, nF);   % default first 3 factors
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
