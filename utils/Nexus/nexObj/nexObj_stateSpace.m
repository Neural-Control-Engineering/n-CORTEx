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
                for i = 1:numel(axFields)
                    axDim = nexObj.DF_postOp.ptr.(axFields{i}).dim;
                    if ~isempty(axDim)
                        ptrDict.(axFields{i}) = nexObj.DF_postOp.ax.(axFields{i});
                    end
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
            nexObj.player = timer('Period', 0.1, 'BusyMode', 'drop', ...
                'ExecutionMode', 'fixedRate', ...
                'TimerFcn', @(~,~) nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams));
        end

        function compileSTAT(nexObj)
            %% STAT — inherit from categorical Parent if available
            % nexOp_compileSTAT is too expensive to call at construction;
            % categorical already holds a compiled STAT from reportStats().
            if ~isempty(nexObj.Parent) && strcmp(nexObj.Parent.classID, 'ctg')
                S_categories = nex_returnSelectionMask(nexObj.Parent.selectionBus.categories);
                S_items = nex_returnSelectionMask(nexObj.Parent.selectionBus.items);
                % nexObj.STAT = nexOp_compileSTAT(nexObj.Parent, nexObj.dfID_source, S_categories, S_items, []);
                nexObj.STAT = nexOp_compileSTAT(nexObj, nexObj.dfID_source, S_categories, S_items, []);
            end
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
            % Compile STAT / AVG / DF into nexObj.STATE and initialize ptr.
            nexObj.compileSTAT();
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
            % one column per DF_postOp.ax field (excluding 'latent').
            % No grouping columns — DF rows are a single unlabelled trajectory.
            if ~isempty(nexObj.DF_postOp)
                try
                    Z_DF  = nexObj.DF_postOp.df;
                    T_DF  = size(Z_DF, 1);
                    S_DF  = zeros(size(Z_DF));
                    G_DF  = table((1:T_DF)', 'VariableNames', {'sampleNumber'});
                    if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax')
                        axFields = fieldnames(nexObj.DF_postOp.ax);
                        axFields = axFields(~strcmp(axFields, 'latent'));
                        for k = 1:numel(axFields)
                            f    = axFields{k};
                            vals = nexObj.DF_postOp.ax.(f)';   % transpose to Nx1
                            idx  = min((1:T_DF)', numel(vals));
                            try
                                G_DF.(f) = vals(idx);
                            catch e
                                disp(getReport(e));
                                keyboard
                            end
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
            % 
            % STATE.Z = [Z_AVG; Z_DF];
            % STATE.S = [S_AVG; S_DF];
            STATE.Z = [Z_AVG];
            STATE.S = [S_AVG];

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

            %% Auto-populate domain.F from ax.latent labels or column count
            if ~isempty(STATE.Z)
                nFactors = size(STATE.Z, 2);
                if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax') ...
                        && isfield(nexObj.DF_postOp.ax, 'latent')
                    nexObj.domain.F = string(nexObj.DF_postOp.ax.latent);
                elseif isempty(nexObj.domain.F) || isequal(nexObj.domain.F, "")
                    nexObj.domain.F = "f" + string(1:nFactors);
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

        function reportAverage(nexObj, resultID, nBins)
            % Average STAT trials grouped by the columns currently selected in
            % the CTG bus.  Continuous columns are quantile-binned into nBins
            % pseudo-categories.  Results go into RESULTS.(resultID) and are
            % exposed in the VW and SRC buses for display.
            if nargin < 3 || isempty(nBins), nBins = 4; end
            if nargin < 2 || isempty(resultID)
                displayLabel = nexObj.buildResultID("AVG", nBins);
                resultID     = nexObj.getResultKey(displayLabel);
                nexObj.resultLabels.(resultID) = char(displayLabel);
            end

            STAT = nexObj.STAT;
            if isempty(STAT) || ~istable(STAT), return; end

            % ── 1. Resolve grouping columns from the CTG bus ──────────────────
            % nex_returnSelectionMask maps listbox indices → the actual column-
            % name strings that the user highlighted in the CTG listbox.
            viewSel   = nex_returnSelectionMask(nexObj.collector.View);
            groupCols = string(viewSel.CTG);
            statCols  = string(STAT.Properties.VariableNames);
            groupCols = groupCols(groupCols ~= "" & ismember(groupCols, statCols));
            if isempty(groupCols), return; end

            % ── 2. Build TF cell array from STAT ──────────────────────────────
            % table2struct on a table whose df column is a cell unwraps each
            % cell into the struct field directly: TF{i}.df = numeric array.
            % That is the form nexOp_trimTF / nexOp_averageTF expect.
            TF = arrayfun(@(s) s, table2struct(STAT), 'UniformOutput', false);

            % ── 3. Attempt SLRT event alignment; fall back silently ───────────
            % nexOp_compileSTAT group-sorts rows so STAT indices can no longer
            % be mapped back to DTS rows for SLRT event lookup.  For latent
            % trajectories the DFs are already time-aligned at extraction.
            try
                TF = nexOp_eventAlignTF(nexObj, TF);
            catch
            end

            % ── 4. Build groupTable with numeric recovery + quantile binning ──
            % nexOp_compileSTAT concatenates all category arrays into a single
            % numeric matrix Y before array2table.  When a string column (e.g.
            % sessionLabel--phase) and a numeric column (e.g. h5--responseThreshold_g)
            % appear together, MATLAB coerces the doubles to strings — so the
            % numeric column ends up as strings in STAT.  str2double recovers
            % the values so quantile binning can proceed correctly.
            groupTable = table();
            for ci = 1:numel(groupCols)
                col = char(groupCols(ci));
                raw = STAT.(col);

                % Attempt numeric recovery for string-encoded float columns
                if ~isnumeric(raw)
                    numTry = str2double(string(raw));
                    if any(~isnan(numTry))   % at least some values parseable
                        raw = numTry;
                    end
                end

                if isnumeric(raw) && numel(unique(raw(~isnan(raw)))) > nBins
                    % Continuous column: quantile-bin into nBins groups.
                    % Each bin is labelled "col_qN(mean_val)" so the label
                    % carries both dimension identity and the bin's centre.
                    vals       = raw(~isnan(raw));
                    edges      = quantile(vals, linspace(0, 1, nBins + 1));
                    edges(end) = edges(end) + abs(edges(end)) * 1e-10 + 1e-10;
                    binIdx     = discretize(raw, edges);
                    labels     = strings(numel(raw), 1);
                    for b = 1:nBins
                        m = binIdx == b;
                        if any(m)
                            labels(m) = sprintf('%s_q%d(%.3g)', col, b, ...
                                mean(raw(m), 'omitnan'));
                        end
                    end
                    labels(isnan(raw)) = "<NaN>";
                    groupTable.(col) = labels;

                elseif isnumeric(raw)
                    % Discrete numeric (few unique values): keep as-is
                    groupTable.(col) = raw;

                else
                    % Already a categorical string column
                    groupTable.(col) = string(raw);
                end
            end
            if width(groupTable) == 0, return; end

            % ── 5. Find unique groups and compute per-group average ───────────
            % findgroups on a table returns G (Nx1 index) and groupIDs (one row
            % per unique combination of all groupTable columns).
            [G, groupIDs] = findgroups(groupTable);
            nG = height(groupIDs);

            df_out  = cell(nG, 1);
            ax_out  = cell(nG, 1);
            ptr_out = cell(nG, 1);
            sem_out = cell(nG, 1);
            valid   = false(nG, 1);

            for g = 1:nG
                % Collect trials that belong to this group; drop empties
                TF_g    = TF(G == g);
                isEmpty = cellfun(@(s) isempty(s) || ~isfield(s,'df') || isempty(s.df), TF_g);
                TF_g    = TF_g(~isEmpty);
                if isempty(TF_g), continue; end

                % Borrow ptr from the first trial (nexOp_averageTF only trims)
                ptr = [];
                if isfield(TF_g{1}, 'ptr') && ~isempty(TF_g{1}.ptr)
                    ptr = TF_g{1}.ptr;
                end

                % nexOp_averageTF trims all DFs to minimum length, then means
                try
                    DF_avg = nexOp_averageTF(TF_g, ptr, 2);
                catch
                    continue;
                end

                % Build a fresh ptr for the averaged df
                DF_avg.ptr = nexInit_axisPointer(DF_avg.df, DF_avg.ax);

                % Store as cells: nexOp_stackSTAT expects iscell(STAT.ax) = true
                df_out{g}  = DF_avg.df;
                ax_out{g}  = DF_avg.ax;
                ptr_out{g} = DF_avg.ptr;
                sem_out{g} = DF_avg.sem;
                valid(g)   = true;
            end
            if ~any(valid), return; end

            % ── 6. Build RESULT table ─────────────────────────────────────────
            % Structural cell columns (df/ax/ptr/sem) + group-label columns from
            % groupIDs.  Cell wrapping is required so nexOp_stackSTAT can later
            % index into them as STAT.ax{k}.
            RESULT = table(df_out(valid), ax_out(valid), ptr_out(valid), sem_out(valid), ...
                'VariableNames', {'df','ax','ptr','sem'});
            RESULT = [RESULT, groupIDs(valid, :)];

            % ── 7. Store and refresh buses ────────────────────────────────────
            nexObj.RESULTS.(resultID) = RESULT;

            % AVG is the legacy source consumed by buildSTATE → nexOp_stackSTAT
            nexObj.AVG = RESULT;

            nexObj.refreshVW();
            nexObj.refreshSRC();
            nexObj.broadcastResult(resultID);

            try
                if ismember('h5_path', nexObj.nexon.console.BASE.DTS.Properties.VariableNames)
                    nexOp_saveResult(nexObj, resultID);
                end
            catch ME
                warning('[%s.reportAverage] auto-save failed: %s', class(nexObj), ME.message);
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
        function vwKeys = getCTGGroupKeys(nexObj)
            % Return all unique category values across EVERY group column of
            % nexObj.AVG.  VW therefore lists one selectable entry per distinct
            % label in each dimension (phase values + threshold-bin labels, etc.).
            % nexVisualization_stateSpace ANDs selections across dimensions so
            % picking "pre" and "thresh_q2(…)" shows only their intersection.
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","cov","sem","labels"];
            if isempty(nexObj.AVG) || ~istable(nexObj.AVG)
                vwKeys = "";
                return;
            end
            cols      = string(nexObj.AVG.Properties.VariableNames)';
            groupCols = cols(~ismember(cols, DF_STRUCT_FIELDS));
            if isempty(groupCols)
                vwKeys = "";
                return;
            end
            % Gather unique values from every group column into one flat list
            all_vals = string.empty(0, 1);
            for ci = 1:numel(groupCols)
                vals     = string(nexObj.AVG.(char(groupCols(ci))));
                all_vals = [all_vals; unique(vals(:))];  %#ok<AGROW>
            end
            vwKeys = unique(all_vals);
            if isempty(vwKeys), vwKeys = ""; end
        end

        function onSRCChanged(nexObj, lb)
            % SRC listbox callback — keeps bus selection index in sync then
            % routes to applySRC so nexObj.AVG always matches the active source.
            nexObj.collector.View.selections.SRC = lb.Value;
            if iscell(lb.String)
                srcKey = lb.String{lb.Value(end)};
            else
                srcKey = char(lb.String(lb.Value(end)));
            end
            nexObj.applySRC(srcKey);
        end

        function applySRC(nexObj, srcKey)
            % Sync nexObj.AVG to the selected source then refresh VW.
            % "DF" → clear AVG so buildSTATE falls back to raw DF data.
            % Any RESULTS key → point AVG at that result table.
            if strcmp(srcKey, 'DF')
                nexObj.AVG = [];
            elseif isfield(nexObj.RESULTS, srcKey)
                nexObj.AVG = nexObj.RESULTS.(srcKey);
            else
                return;
            end
            nexObj.refreshVW();
        end

        function refreshVW(nexObj)
            % Full three-field update of VW selectionBus after AVG is populated.
            % Must update selKeys, selection index, AND listbox — updating only
            % selKeys leaves the listbox stale and index potentially out of range.
            % (Pattern from nexOp_sBus_alignItems2ax.)
            if ~isfield(nexObj.collector, 'View'), return; end
            newKeys = nexObj.getCTGGroupKeys();
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
