classdef nexObject < handle

    properties
        headline
        classID
        Parent
        Partners
        Children
        Origin
        nexon
        DF
        dfID_source
        DF_postOp
        dfID_target
        pMap
        collector
        RESULTS = struct()
        STAT     = []
        domain
        Figure
        UserData
        cfg=struct
        player
    end

    methods
        function nexObj = nexObject(nexon, Parent, dfID_source, headline)
            nexObj.nexon = nexon;
            nexObj.Parent = Parent;
            nexObj.dfID_source = dfID_source;
            nexObj.UserData.preBufferLen=3.5;
            if nargin >= 4 && ~isempty(headline)
                nexObj.headline = headline;
            end
        end

        function applyHeadline(nexObj)
            if ~isempty(nexObj.headline) && isfield(nexObj.Figure, 'fh') && isvalid(nexObj.Figure.fh)
                nexObj.Figure.fh.Name = nexObj.headline;
            end
        end

        function domain = inferDomain(nexObj)
            % Canonical domain inference — inherited by all nexObject subclasses.
            % First call (domain.D2 not yet set): auto-infers D2 from 't' axis.
            % Subsequent calls (domain.D2 already set): respects existing D2 and
            % animate, recomputing only D1 as the complement.
            % Subclasses may override for non-standard axis layouts.

            axFields = string(fieldnames(nexObj.DF_postOp.ax))';
            domain.axes = axFields;
            domain.F    = string(nexObj.dfID_source);

            % D2: respect existing if set; otherwise auto-infer ('t' → first axis)
            if isfield(nexObj.domain, 'D2') && ~isempty(nexObj.domain.D2)
                domain.D2 = nexObj.domain.D2;
            else
                tKey = axFields(axFields == "t");
                if ~isempty(tKey)
                    domain.D2 = string(tKey(1));
                else
                    domain.D2 = string(axFields(1));
                end
            end

            % animate: respect existing if still a valid member of D2; else D2(1)
            if isfield(nexObj.domain, 'animate') && ~isempty(nexObj.domain.animate) ...
                    && any(domain.D2 == nexObj.domain.animate)
                domain.animate = nexObj.domain.animate;
            else
                domain.animate = domain.D2(1);
            end

            % D1 always recomputed as complement of full D2 array
            domain.D1 = string(setdiff(axFields, domain.D2, "stable"));
        end

        function setAnimateAxis(nexObj, axKey)
            % Replace D2 with the selected axis and re-run inferDomain for D1.
            % D2 is a string array to support future multi-axis selection via
            % nexObj_selectionBus, but the dropdown replaces rather than accumulates.
            nexObj.domain.D2      = string(axKey);
            nexObj.domain.animate = string(axKey);
            nexObj.domain = nexObj.inferDomain();
        end

        % -- POOLING -------------------------------------------------------
        function poolDF(nexObj)
            nexObj.DF_postOp = nexOp_poolAxes(nexObj.pMap, nexObj.DF_postOp, nexObj.DF_postOp.ptr);
        end

        % ── Player ────────────────────────────────────────────────────────
        function startPlayer(nexObj)
            isPlay = nexObj.Figure.playButton.Value;
            switch isPlay
                case 0, nexObj.player.start;
                case 1, nexObj.player.stop;
            end
        end

        function stepAnimate(nexObj, args)
            % CFG HEADER
            stride = args.stride; % default = 1
            len_afterImage = args.len_afterImage; % default = 10
            % Advance the animation pointer by stride steps along
            % domain.animate, then call visualize(). Wraps around at
            % axis length. Inherited by all nexObject subclasses.
            % domain.animate is written by the UI axSelDropDown so that
            % the axis being stepped is dynamically selectable.
            axSel  = nexObj.domain.animate;
            curVal = nexObj.DF_postOp.ptr.(axSel).value;
            % Step through Pointer bus selection as a sequence when available —
            % handles discontinuous selections and snaps to sel(1) if curVal
            % is not currently in sel (e.g. on first step after initialization).
            if isfield(nexObj.collector, 'Pointer') && ~isempty(nexObj.collector.Pointer) ...
                    && isfield(nexObj.collector.Pointer.selections, axSel)
                sel = nexObj.collector.Pointer.selections.(axSel);
                if ~isempty(sel)
                    curPos = find(sel == curVal, 1);
                    if isempty(curPos), curPos = 1 - stride; end  % snaps to sel(1) on first step
                    axVal = sel(mod(curPos - 1 + stride, numel(sel)) + 1);
                else
                    r     = nexObj.DF_postOp.ptr.(axSel).range;
                    span  = r(2) - r(1) + 1;
                    axVal = r(1) + mod(curVal - r(1) + stride, span);
                end
            else
                r     = nexObj.DF_postOp.ptr.(axSel).range;
                span  = r(2) - r(1) + 1;
                axVal = r(1) + mod(curVal - r(1) + stride, span);
            end
            nexObj.DF_postOp.ptr.(axSel).value = axVal;
            nexObj.visualize();
        end

        function tile(nexObj, tilesPerRow, steps)
            % Iterates the animate pointer across all steps, captures each
            % visualization, and lays them out in a new tiled figure.
            % The TL handle is stored in nexObj.UserData.TL<N>.
            
            axSel  = char(nexObj.domain.animate);
            ptr    = nexObj.DF_postOp.ptr.(axSel);

            if nargin <3 % steps unused
                % Resolve step indices — respect Pointer selection if active
                if isfield(nexObj.collector, 'Pointer') && ~isempty(nexObj.collector.Pointer) ...
                        && isfield(nexObj.collector.Pointer.selections, axSel) ...
                        && ~isempty(nexObj.collector.Pointer.selections.(axSel))
                    selVals = nexObj.collector.Pointer.selections.(axSel);
                    axVals  = nexObj.DF_postOp.ax.(axSel);
                    steps   = find(ismember(axVals, selVals));
                else
                    % r     = ptr.range;
                    % steps = r(1):r(2);
                    steps = [1:length(nexObj.DF_postOp.ax.(axSel))];
                end
            end
            nSteps = numel(steps);

            % Build tiled layout
            nRows  = ceil(nSteps / tilesPerRow);
            fig_TL = figure('Color', 'k');
            TL     = tiledlayout(fig_TL, nRows, tilesPerRow, ...
                         'TileSpacing', 'compact', 'Padding', 'compact');

            % Register under next available TL<N> key in UserData
            if isempty(nexObj.UserData) || ~isstruct(nexObj.UserData)
                nexObj.UserData = struct();
            end
            existingKeys = fieldnames(nexObj.UserData);
            % tlN   = sum(startsWith(existingKeys, 'TL')) + 1;
            % tlKey = sprintf('TL', tlN);
            tlKey="TL";
            nexObj.UserData.(tlKey) = TL;

            % Save current ptr value to restore after tiling
            origVal = ptr.value;
            srcAx   = nexObj.Figure.panel0.tiles.ax;

            for k = 1:nSteps
                nexObj.DF_postOp.ptr.(axSel).value = steps(k);
                nexObj.visualize();
                drawnow;

                destAx                 = nexttile(TL);
                copyobj(srcAx.Children, destAx);
                destAx.Color           = srcAx.Color;
                destAx.XLim            = srcAx.XLim;
                destAx.YLim            = srcAx.YLim;
                destAx.ZLim            = srcAx.ZLim;
                destAx.View            = srcAx.View;
                destAx.XColor          = srcAx.XColor;
                destAx.YColor          = srcAx.YColor;
                destAx.ZColor          = srcAx.ZColor;
                destAx.XGrid           = srcAx.XGrid;
                destAx.YGrid           = srcAx.YGrid;
                destAx.ZGrid           = srcAx.ZGrid;
                destAx.GridColor       = srcAx.GridColor;
                destAx.GridAlpha       = srcAx.GridAlpha;
                destAx.MinorGridColor  = srcAx.MinorGridColor;
                destAx.MinorGridAlpha  = srcAx.MinorGridAlpha;
                destAx.LineWidth       = srcAx.LineWidth;
                destAx.FontSize        = srcAx.FontSize;                
                destAx.Box             = srcAx.Box;
                destAx.Colormap        = srcAx.Colormap;
                destAx.CLim            = srcAx.CLim;
                title(destAx, srcAx.Title.String, 'Color', srcAx.Title.Color);
                destAx.XLabel.String   = srcAx.XLabel.String;
                destAx.XLabel.Color    = srcAx.XLabel.Color;
                destAx.YLabel.String   = srcAx.YLabel.String;
                destAx.YLabel.Color    = srcAx.YLabel.Color;
                destAx.ZLabel.String   = srcAx.ZLabel.String;
                destAx.ZLabel.Color    = srcAx.ZLabel.Color;
            end

            % Restore original state
            nexObj.DF_postOp.ptr.(axSel).value = origVal;
            nexObj.visualize();
        end

        function gif(nexObj)
        end

        function state = saveState(nexObj)
        % Serialize selection state, cfg, and domain into a plain struct.
        % The manifest nexon and live DTS are NOT included — those are
        % supplied separately via nexon_fromManifest at load time.
            state.className   = class(nexObj);
            state.classID     = char(nexObj.classID);
            state.dfID_source = char(nexObj.dfID_source);
            state.headline    = char(nexObj.headline);
            state.domain      = nexObj_serializeDomain(nexObj.domain);
            state.cfg         = nex_serializeCfg(nexObj.cfg);
            state.collector   = nexObj_serializeCollector(nexObj.collector);
            if isprop(nexObj, 'selectionBus') && ~isempty(nexObj.selectionBus)
                state.selectionBus = nexObj_serializeSelectionBus(nexObj.selectionBus);
            end
        end

        % ── Collector / RESULTS suite ─────────────────────────────────────
        % These methods are generic and work for any nexObject subclass that
        % carries a STAT table and a collector.View bus (AVG / VW / CLR / SRC).
        % Subclasses may override individual methods to add subclass-specific
        % side-effects (e.g. rebuildTrackers, visualize) by calling the base
        % via nexObject.method(nexObj, ...) before or after the extra logic.

        function compileSTAT(nexObj)
            % Compile STAT from Parent categorical using current selections.
            % Requires nexObj.dfID_source to be a real data ID (not a placeholder).
            if isempty(nexObj.Parent) || ~strcmp(nexObj.Parent.classID, 'ctg') ...
                    || isempty(nexObj.dfID_source)
                return;
            end
            S_cat   = nex_returnSelectionMask(nexObj.Parent.selectionBus.categories);
            S_items = nex_returnSelectionMask(nexObj.Parent.selectionBus.items);
            try
                nexObj.STAT = nexOp_compileSTAT(nexObj, nexObj.dfID_source, S_cat, S_items, []);
            catch e
                disp(getReport(e));
            end
        end

        function initCollectorView(nexObj)
            % Initialise collector.View (AVG / VW / CLR / SRC) from current STAT.
            % Call after compileSTAT() so AVG/CLR keys are populated.
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","sem"];
            if ~isempty(nexObj.STAT) && istable(nexObj.STAT)
                allCols = string(nexObj.STAT.Properties.VariableNames)';
                grpKeys = allCols(~ismember(allCols, DF_STRUCT_FIELDS));
                if isempty(grpKeys), grpKeys = ""; end
            else
                grpKeys = "";
            end
            viewDict.AVG = grpKeys;
            viewDict.VW  = nexObj.getAVGGroupKeys();
            viewDict.CLR = grpKeys;
            nexObj.collector.View = nexInit_collectorView(nexObj, viewDict);
        end

        function reportAverage(nexObj, resultID, nBins, STAT)
            % Group STAT by AVG bus selection, average per group, store in RESULTS.
            % resultID auto-generated when omitted.  nBins controls quantile
            % binning for continuous grouping columns (default 4).
            if nargin < 2 || isempty(resultID)
                resultID = sprintf('avg%d', numel(fieldnames(nexObj.RESULTS)) + 1);
            end
            if nargin < 3, nBins = 4; end
            if nargin < 4; STAT = nexObj.STAT; end

            % STAT = nexObj.STAT;
            if isempty(STAT) || ~istable(STAT)
                fprintf('[%s.reportAverage] STAT is empty — call compileSTAT() first.\n', class(nexObj));
                return;
            end

            viewSel   = nex_returnSelectionMask(nexObj.collector.View);
            groupCols = string(viewSel.AVG);
            statCols  = string(STAT.Properties.VariableNames);
            groupCols = groupCols(groupCols ~= "" & ismember(groupCols, statCols));
            if isempty(groupCols)
                fprintf('[%s.reportAverage] No AVG columns selected.\n', class(nexObj));
                return;
            end

            TF = arrayfun(@(s) s, table2struct(STAT), 'UniformOutput', false);
            try, TF = nexOp_eventAlignTF(nexObj, TF); catch, end

            groupTable = table();
            for ci = 1:numel(groupCols)
                col = char(groupCols(ci));
                raw = STAT.(col);
                if ~isnumeric(raw)
                    numTry = str2double(string(raw));
                    if any(~isnan(numTry)), raw = numTry; end
                end
                if isnumeric(raw) && nexOp_isContinuousVar(raw) && numel(unique(raw(~isnan(raw)))) > nBins
                    vals   = raw(~isnan(raw));
                    edges  = quantile(vals, linspace(0, 1, nBins + 1));
                    edges(end) = edges(end) + abs(edges(end)) * 1e-10 + 1e-10;
                    binIdx = discretize(raw, edges);
                    labels = strings(numel(raw), 1);
                    for b = 1:nBins
                        m = binIdx == b;
                        if any(m)
                            labels(m) = sprintf('%s_q%d(%.3g)', col, b, mean(raw(m), 'omitnan'));
                        end
                    end
                    labels(isnan(raw)) = "<NaN>";
                    groupTable.(col) = labels;
                elseif isnumeric(raw)
                    groupTable.(col) = raw;
                else
                    groupTable.(col) = string(raw);
                end
            end
            if width(groupTable) == 0, return; end

            [G, groupIDs] = findgroups(groupTable);
            nG     = height(groupIDs);
            df_out  = cell(nG, 1);  ax_out  = cell(nG, 1);
            ptr_out = cell(nG, 1);  sem_out = cell(nG, 1);
            valid   = false(nG, 1);

            for g = 1:nG
                TF_g    = TF(G == g);
                isEmpty = cellfun(@(s) isempty(s) || ~isfield(s,'df') || isempty(s.df), TF_g);
                TF_g    = TF_g(~isEmpty);
                if isempty(TF_g), continue; end
                ptr = [];
                if isfield(TF_g{1}, 'ptr') && ~isempty(TF_g{1}.ptr)
                    ptr = TF_g{1}.ptr;
                end
                try
                    DF_avg = nexOp_averageTF(TF_g, ptr, 2);
                catch
                    continue;
                end
                DF_avg.ptr = nexInit_axisPointer(DF_avg.df, DF_avg.ax);
                df_out{g}  = DF_avg.df;   ax_out{g}  = DF_avg.ax;
                ptr_out{g} = DF_avg.ptr;  sem_out{g} = DF_avg.sem;
                valid(g)   = true;
            end
            if ~any(valid), return; end

            RESULT = table(df_out(valid), ax_out(valid), ptr_out(valid), sem_out(valid), ...
                'VariableNames', {'df','ax','ptr','sem'});
            RESULT = [RESULT, groupIDs(valid, :)];

            nexObj.RESULTS.(resultID) = RESULT;

            % Update SRC bus before refreshVW so getCurrentSRC() returns the
            % new resultID and getAVGGroupKeys can read the correct RESULTS entry.
            if isfield(nexObj.collector, 'View')
                bus  = nexObj.collector.View;
                keys = ["DF"; string(fieldnames(nexObj.RESULTS))];
                bus.selKeys.SRC    = keys;
                bus.selections.SRC = numel(keys);
                if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC)
                    bus.listBoxes.SRC.String = keys;
                    bus.listBoxes.SRC.Max    = 1;
                    bus.listBoxes.SRC.Value  = numel(keys);
                end
            end

            nexObj.refreshVW();

            fprintf('[%s.reportAverage] %d groups → RESULTS.%s\n', class(nexObj), sum(valid), resultID);
        end

        function srcKey = getCurrentSRC(nexObj)
            % Return the currently selected SRC key, or 'DF' as fallback.
            try
                bus    = nexObj.collector.View;
                idx    = bus.selections.SRC;
                srcKey = char(bus.selKeys.SRC(idx(end)));
            catch
                srcKey = 'DF';
            end
        end

        function vwKeys = getAVGGroupKeys(nexObj)
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","cov","sem","labels"];
            srcKey = nexObj.getCurrentSRC();
            if strcmp(srcKey, 'DF') || ~isfield(nexObj.RESULTS, srcKey)
                vwKeys = ""; return;
            end
            tbl = nexObj.RESULTS.(srcKey);
            if isempty(tbl) || ~istable(tbl), vwKeys = ""; return; end
            cols      = string(tbl.Properties.VariableNames)';
            groupCols = cols(~ismember(cols, DF_STRUCT_FIELDS));
            if isempty(groupCols), vwKeys = ""; return; end
            all_vals = string.empty(0, 1);
            for ci = 1:numel(groupCols)
                vals     = string(tbl.(char(groupCols(ci))));
                all_vals = [all_vals; unique(vals(:))]; %#ok<AGROW>
            end
            vwKeys = unique(all_vals);
            if isempty(vwKeys), vwKeys = ""; end
        end

        function refreshVW(nexObj)
            % Update VW selectionBus from current RESULTS source.
            % Preserves previously selected labels when they still exist in the
            % new key set (e.g. switching between RESULTS with shared labels).
            % Falls back to all-selected only when nothing carries over.
            % Subclasses that need structural side-effects (e.g. rebuildTrackers)
            % should override and call refreshVW@nexObject(nexObj) first.
            if ~isfield(nexObj.collector, 'View'), return; end
            newKeys = nexObj.getAVGGroupKeys();
            bus     = nexObj.collector.View;
            nVW     = numel(newKeys);

            oldKeys = bus.selKeys.VW;
            oldSel  = bus.selections.VW;
            if ~isempty(oldKeys) && ~isempty(oldSel) && ~isequal(oldKeys, "")
                validOld   = oldSel(oldSel >= 1 & oldSel <= numel(oldKeys));
                prevLabels = string(oldKeys(validOld));
                newSel     = find(ismember(newKeys, prevLabels))';
                if isempty(newSel), newSel = 1:nVW; end
            else
                newSel = 1:nVW;
            end

            bus.selKeys.VW    = newKeys;
            bus.selections.VW = newSel;
            if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW)
                bus.listBoxes.VW.String = newKeys;
                bus.listBoxes.VW.Max    = nVW;
                bus.listBoxes.VW.Value  = newSel;
            end
        end

        function onSRCChanged(nexObj, lb)
            nexObj.collector.View.selections.SRC = lb.Value;
            if iscell(lb.String)
                srcKey = lb.String{lb.Value(end)};
            else
                srcKey = char(lb.String(lb.Value(end)));
            end
            nexObj.applySRC(srcKey);
        end

        function applySRC(nexObj, srcKey)
            % Update the SRC bus selection and refresh the VW bus.
            % Subclasses that need additional side-effects (e.g. visualize)
            % override and call applySRC@nexObject(nexObj, srcKey) first.
            if ~isfield(nexObj.collector, 'View'), return; end
            if ~strcmp(srcKey, 'DF') && ~isfield(nexObj.RESULTS, srcKey), return; end
            bus  = nexObj.collector.View;
            idx  = find(string(bus.selKeys.SRC) == string(srcKey), 1);
            if isempty(idx), return; end
            bus.selections.SRC = idx;
            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC)
                bus.listBoxes.SRC.Value = idx;
            end
            nexObj.refreshVW();
        end

        function C = resolveGroupColors(nexObj, dataTable, clrCols)
            % Two-pass color resolution via nexOp_resolveGroupColors.
            % Pass 1 (RGB): matched columns (LUT/atlas) contribute N×3 layers,
            %   averaged and normalised so blended hue stays vivid.
            % Pass 2: unmatched columns — if no LUT base, use first column's HSV
            %   spread directly; if LUT base present, subtle hue/sat rotation.
            GREEN = nexObj.nexon.settings.Colors.cyberGreen;
            N     = height(dataTable);
            C     = repmat(GREEN, N, 1);
            if isempty(clrCols) || N == 0, return; end

            gCols   = string(dataTable.Properties.VariableNames);
            C_lut   = {};
            C_hsv   = {};
            hsv_mod = {};

            for ci = 1:numel(clrCols)
                col = char(clrCols(ci));
                if ~ismember(col, gCols), continue; end
                [C_ci, matched] = nexOp_resolveGroupColors( ...
                    nexObj.nexon, col, string(dataTable.(col)));
                if matched
                    C_lut{end+1} = C_ci;              %#ok<AGROW>
                else
                    C_hsv{end+1}   = C_ci;            %#ok<AGROW>
                    hsv_mod{end+1} = string(dataTable.(col)); %#ok<AGROW>
                end
            end

            % Pass 1 — average LUT/atlas layers; normalise so blended hue stays vivid
            if ~isempty(C_lut)
                C = mean(cat(3, C_lut{:}), 3);
                if numel(C_lut) > 1
                    maxC = max(C, [], 2);
                    maxC(maxC < eps) = 1;
                    C = C ./ maxC;
                end
            end

            % Pass 2 — unmatched columns
            if ~isempty(hsv_mod)
                if isempty(C_lut)
                    C = C_hsv{1};   % no LUT base — use first unmatched spread directly
                else
                    % hue_spread = 0.45;
                    hue_spread = 1/12;
                    sat_lo     = 0.45;
                    val_lo     = 0.80;
                    hsv_c = rgb2hsv(C);
                    for mi = 1:numel(hsv_mod)
                        vals   = hsv_mod{mi};
                        uniq_v = unique(vals, 'stable');
                        n_u    = numel(uniq_v);
                        t     = linspace(0, 1, max(n_u, 2));
                        h_off = linspace(-hue_spread/2, hue_spread/2, max(n_u, 2));
                        for k = 1:n_u
                            m = vals == uniq_v(k);
                            hsv_c(m, 1) = mod(hsv_c(m, 1) + h_off(k), 1);
                            hsv_c(m, 2) = sat_lo + (1 - sat_lo) * t(k);
                            hsv_c(m, 3) = max(hsv_c(m, 3), val_lo + (1 - val_lo) * t(k));
                        end
                    end
                    C = hsv2rgb(hsv_c);
                end
            end
        end

        % ── Pointer bus ───────────────────────────────────────────────────

        function initPointerBus(nexObj)
        % Build collector.Pointer from DF_postOp.ax — one key per axis,
        % values = axis tick labels. Single-item default = pass-through.
            srcAx = struct();
            try, srcAx = nexObj.DF_postOp.ax; catch, end
            if isempty(srcAx) || isempty(fieldnames(srcAx))
                nexObj.collector.Pointer = []; return;
            end
            try
                axFields = fieldnames(srcAx);
                ptrDict  = struct();
                for i = 1:numel(axFields)
                    f    = axFields{i};
                    vals = srcAx.(f);
                    if ~isempty(vals), ptrDict.(f) = vals; end
                end
                if ~isempty(fieldnames(ptrDict))
                    nexObj.collector.Pointer = buildSelection(nexObj, ptrDict);
                else
                    nexObj.collector.Pointer = [];
                end
            catch
                nexObj.collector.Pointer = [];
            end
        end

        function buildPointerPanel(nexObj, panelParent, position)
        % Create a scrollable Pointer panel wired to collector.Pointer.
        % Does nothing if collector.Pointer is empty.
            if isempty(nexObj.collector.Pointer), return; end
            BLACK = [0 0 0];
            GREEN = nexObj.nexon.settings.Colors.cyberGreen;
            pan_ptr.ph = uipanel(panelParent, ...
                'Position',        position, ...
                'BackgroundColor', BLACK, ...
                'Scrollable',      'on', ...
                'Title',           'Pointer', ...
                'ForegroundColor', GREEN);
            nexObj.Figure.panel_pointer = nexObj_listCfgPanel( ...
                nexObj.nexon, pan_ptr, nexObj.collector.Pointer, []);
        end

        function TF = applyPointerTF(nexObj, TF)
        % Slice each DF cell in TF along axes where collector.Pointer has a
        % non-trivial selection (fewer than all values selected).
        % Single-item default selections are treated as pass-through.
            bus = nexObj.collector.Pointer;
            if isempty(bus), return; end
            axFields = fieldnames(bus.selections);
            if isempty(axFields), return; end

            % Find first non-empty DF to derive axis→dimension mapping
            refDF = [];
            for ri = 1:numel(TF)
                c = TF{ri};
                if ~isempty(c) && isfield(c,'df') && ~isempty(c.df) && isfield(c,'ax')
                    refDF = c; break;
                end
            end
            if isempty(refDF), return; end
            if ~isfield(refDF,'ptr') || isempty(refDF.ptr)
                refDF = nex_initAxisPointer_v2(refDF);
            end

            for ai = 1:numel(axFields)
                f      = axFields{ai};
                selIdx = bus.selections.(f);
                if numel(selIdx) <= 1, continue; end   % single item = no window

                allVals      = bus.selKeys.(f);
                selectedVals = allVals(selIdx);
                if ~isfield(refDF.ax, f), continue; end
                axVals = refDF.ax.(f);
                if numel(selectedVals) == numel(axVals), continue; end  % all = no-op

                if isnumeric(selectedVals) && isnumeric(axVals)
                    sc = max(abs(double(axVals(:)))); if sc == 0, sc = 1; end
                    [tf2, loc] = ismembertol(double(selectedVals(:)), double(axVals(:)), ...
                                             1e-3, 'DataScale', sc);
                    dimIdx = sort(loc(tf2));
                else
                    [~, dimIdx] = ismember(selectedVals, axVals);
                    dimIdx = sort(dimIdx(dimIdx > 0));
                end
                if isempty(dimIdx) || numel(dimIdx) == numel(axVals), continue; end

                dim = refDF.ptr.(f).dim;
                TF  = cellfun(@(c) nexObj_sliceCell(c, f, dim, dimIdx, axVals), ...
                              TF, 'UniformOutput', false);

                S = repmat({':'}, 1, ndims(refDF.df)); S{dim} = dimIdx;
                refDF.df     = refDF.df(S{:});
                refDF.ax.(f) = axVals(dimIdx);

                fprintf('[nexObject.applyPointerTF] %s [%d → %d]\n', ...
                        f, numel(axVals), numel(dimIdx));
            end
        end

        % ─────────────────────────────────────────────────────────────────
        function reloadFromRouter(nexObj)
            nexObj.DF = dtsIO_readDF(nexObj.nexon, nexObj.dfID_source, []);
            nexObj.operate();
            nexObj.visualize();
        end

        % ─────────────────────────────────────────────────────────────────
        function  reportSTAT(nexObj, fcn, compareVars, groupVars, resID, dfID, nBins)

            % CFG HEADER
            k     = 2;            

            if nargin < 6 || isempty(dfID), dfID  = nexObj.dfID_source; end
            if nargin < 7,                  nBins = [];                  end            
            nexObj.RESULTS.(resID) = nexOp_reportSTAT(nexObj, dfID, fcn, compareVars, groupVars, k, nBins);
            % UPDATE UI
            if ismethod(nexObj,"refreshSRC")
                nexObj.refreshSRC();
            end
        end


    end

end

% ── Local helpers ─────────────────────────────────────────────────────────────

function c = nexObj_sliceCell(c, axField, dim, dimIdx, axVals)
% Slice c.df along dim at dimIdx and update c.ax.(axField).
    if isempty(c) || ~isfield(c, 'df') || isempty(c.df), return; end
    S      = repmat({':'}, 1, ndims(c.df));
    S{dim} = dimIdx;
    c.df   = c.df(S{:});
    c.ax.(axField) = axVals(dimIdx);
end

function rgb = nex_blendCrossLabelRGB(label, lut)
% Blend colors for cross-comparison labels of the form 'A-×-B[-×-C...]'.
% Each component is looked up in lut; colors are blended via HSV circular-mean
% hue so e.g. blue (240°) + yellow (60°) → green-cyan (150°).
% Same-component pairs (A-×-A) return the component color directly.
    parts = strsplit(label, '-×-');
    if numel(parts) < 2, rgb = []; return; end
    lutLabels = string(lut.label);
    colors = zeros(0, 3);
    for p = 1:numel(parts)
        idx = find(lutLabels == string(strtrim(parts{p})), 1);
        if isempty(idx), continue; end
        hex = char(lut.color(idx));
        colors(end+1, :) = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255; %#ok<AGROW>
    end
    if isempty(colors), rgb = []; return; end
    if size(colors, 1) == 1, rgb = colors; return; end
    % All identical (e.g. A-x-A) → return component color directly
    if all(vecnorm(colors - colors(1,:), 2, 2) < 1e-6)
        rgb = colors(1,:); return;
    end
    % HSV circular-mean hue; arithmetic mean S and V
    hsv    = rgb2hsv(colors);
    angles = hsv(:,1) * 2 * pi;
    hue    = mod(atan2(mean(sin(angles)), mean(cos(angles))) / (2*pi), 1);
    rgb    = hsv2rgb([hue, mean(hsv(:,2)), mean(hsv(:,3))]);
end

% ── Local serialization helpers ───────────────────────────────────────────────

function dom = nexObj_serializeDomain(domain)
    dom = struct();
    if isempty(domain), return; end
    fields = fieldnames(domain);
    for i = 1:numel(fields)
        f   = fields{i};
        val = domain.(f);
        if isstring(val) || ischar(val) || isnumeric(val)
            dom.(f) = val;
        end
    end
end

function col = nexObj_serializeCollector(collector)
    col = struct();
    if isempty(collector), return; end
    fields = fieldnames(collector);
    for i = 1:numel(fields)
        f   = fields{i};
        val = collector.(f);
        if isa(val, 'nexObj_selectionBus')
            col.(f) = nex_returnSelectionMask(val);
        elseif isstruct(val)
            col.(f) = nexObj_serializePrimitives(val);
        elseif isstring(val) || ischar(val) || isnumeric(val) || islogical(val)
            col.(f) = val;
        end
    end
end

function sbs = nexObj_serializeSelectionBus(selectionBus)
    sbs = struct();
    if isempty(selectionBus), return; end
    fields = fieldnames(selectionBus);
    for i = 1:numel(fields)
        f   = fields{i};
        bus = selectionBus.(f);
        if isa(bus, 'nexObj_selectionBus')
            sbs.(f) = nex_returnSelectionMask(bus);
        end
    end
end

function out = nexObj_serializePrimitives(s)
    out = struct();
    fields = fieldnames(s);
    for i = 1:numel(fields)
        f   = fields{i};
        val = s.(f);
        if isstring(val) || ischar(val) || isnumeric(val) || islogical(val)
            out.(f) = val;
        elseif isstruct(val)
            out.(f) = nexObj_serializePrimitives(val);
        end
    end
end