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
        Listeners    = struct()
        resultLabels = struct()   % structKey → human-readable display label
        source                    % live model/data source this nexObject
            % watches (e.g. an mdlObj) when constructed via
            % resolveNexonFromSource/wireModelSource instead of the usual
            % categorical-Parent/dfID path — empty otherwise. Promoted
            % from nexObj_bar, which originated this pattern.
        viewFacet    = "accuracy"   % which per-row array/ax/ptr triple a
            % RESULTS-backed SRC selection currently pulls from (e.g. "df"
            % vs mdlObject-family "W" — feature weights, or any future
            % faculty a model-results viewer adds). "accuracy" is the
            % default/only-ever-present faculty (df), so this is inert for
            % any nexObject that never grows a second one. See
            % remodelDomain / applySRC overrides that consume it.
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

        function wireModelSource(nexObj, source)
        % Watch a live model/data source (e.g. an mdlObj) and register
        % lazy RESULTS stubs — extracted from nexObj_bar's own
        % constructor (which originated this pattern) so any subclass
        % gets it by calling this instead of duplicating it. Call AFTER
        % obj@nexObject(...) — needs a live nexObj to wire Partners.viewer
        % onto. Pair with the Static resolveNexonFromSource, which runs
        % BEFORE the superclass constructor (no instance exists yet at
        % that point, so that half can't be a regular method).
        %
        % RESULTS.(id) = [] populates the SRC list immediately (cheap —
        % just names); the real table is pulled only when that key is
        % actually selected (applySRC's own lazy-load). Avoids eager
        % deep-copying every one of a source's RESULTS tables up front —
        % a cvPermute RESULTS table can be a genuinely large N-D score
        % array, and a source can accumulate several over a session.
            if isempty(source) || isa(source, 'Nexon'), return; end
            nexObj.source = source;
            if ~isstruct(source.Partners), source.Partners = struct(); end
            source.Partners.viewer = nexObj;
            if isstruct(source.RESULTS) && ~isempty(fieldnames(source.RESULTS))
                ids = string(fieldnames(source.RESULTS))';
                for i = 1:numel(ids)
                    nexObj.RESULTS.(ids(i)) = [];
                end
            end
        end

        function push(nexObj, resultID, R)
        % Companion to wireModelSource — a source's storeResult calls this
        % on Partners.viewer to keep an already-attached, already-loaded
        % viewer in sync on every re-run under the SAME resultID (the
        % lazy-load stub in wireModelSource only fires once, on first
        % selection, so without this a viewer's cached copy goes stale the
        % moment the source re-fits and overwrites that resultID).
        % Extracted verbatim from nexObj_bar's own push (which originated
        % this pattern and keeps its own identical override, unaffected by
        % this promotion) — fully generic, no bar-specific behavior here
        % at all, so any other mdlObj-sourced viewer (e.g. nexObj_monoGram)
        % gets it for free instead of erroring with "Unrecognized method
        % ... 'push'" the first time a source tries to notify it.
            nexObj.RESULTS.(resultID) = R;
            nexObj.refreshSRC();
        end

        function applyHeadline(nexObj)
            if ~isempty(nexObj.headline) && isfield(nexObj.Figure, 'fh') && isvalid(nexObj.Figure.fh)
                nexObj.Figure.fh.Name = nexObj.headline;
            end
            if isfield(nexObj.Figure, 'fh') && isvalid(nexObj.Figure.fh)
                nexObj.Figure.fh.CloseRequestFcn = @(~,~) nexObj.closeFcn();
            end
        end

        function closeFcn(nexObj)
            % Stop animation timer cleanly before the figure disappears.
            try
                if ~isempty(nexObj.player) && isvalid(nexObj.player) ...
                        && strcmp(nexObj.player.Running, 'on')
                    nexObj.player.stop();
                end
            catch
            end
            % Remove from launcher registry so nexRefresh does not try to
            % reach a deleted figure handle.
            try
                figs = nexObj.nexon.UserData.launchedFigures;
                nexObj.nexon.UserData.launchedFigures = ...
                    figs(~cellfun(@(f) isequal(f, nexObj), figs));
            catch
            end
            % Close the figure.
            try
                if isfield(nexObj.Figure, 'fh') && isvalid(nexObj.Figure.fh)
                    delete(nexObj.Figure.fh);
                end
            catch
            end
        end

        function domain = inferDomain(nexObj)
            % Canonical domain inference — inherited by all nexObject subclasses.
            % First call (domain.D2 not yet set): auto-infers D2 from 't' axis.
            % Subsequent calls (domain.D2 already set): respects existing D2 and
            % animate, recomputing only D1 as the complement.
            % Subclasses may override for non-standard axis layouts.

            try
                axFields = string(fieldnames(nexObj.DF_postOp.ax))';
            catch
                keyboard
            end
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

            % REG: respect existing if set; otherwise default to "None" —
            % same convention mdlObject.domain.REG uses. nexObject.domain
            % never had a REG field before, which meant nexOp_compileSTAT's
            % own co-axis-alignment gate (isfield(nexObj.domain,'REG'))
            % was always false for a plain nexObject — canonicalization
            % could never run at all for e.g. reportAverage, regardless of
            % configuration, since there was nowhere to even hold the
            % selection. "None" here is a no-op default (matches
            % nexOp_compileSTAT's own ~strcmp(...,'None') gate) — this
            % only makes REG reachable, it doesn't turn alignment on by
            % itself.
            if isfield(nexObj.domain, 'REG') && ~isempty(nexObj.domain.REG)
                domain.REG = nexObj.domain.REG;
            else
                domain.REG = "None";
            end
        end

        function setAnimateAxis(nexObj, axKey)
            % Replace D2 with the selected axis and re-run inferDomain for D1.
            % D2 is a string array to support future multi-axis selection via
            % nexObj_selectionBus, but the dropdown replaces rather than accumulates.
            nexObj.domain.D2      = string(axKey);
            nexObj.domain.animate = string(axKey);
            nexObj.domain = nexObj.inferDomain();
        end

        % ── Domain bus callbacks ──────────────────────────────────────────
        function onD1Changed(nexObj, lb)
            nexObj.collector.Domain.selections.D1 = lb.Value;
            nexObj.visualize();
        end

        function onANIChanged(nexObj, lb)
            nexObj.collector.Domain.selections.ANI = lb.Value;
            aniKeys = nexObj.collector.Domain.selKeys.ANI;
            if ~isempty(lb.Value) && ~isempty(aniKeys)
                nexObj.domain.animate = string(aniKeys(lb.Value(end)));
                nexObj.clearAnimatePointer();
            end
            nexObj.visualize();
        end

        function refreshREG(nexObj)
            % Recompute REG listbox candidates (if a subclass has wired a
            % REG key into its own collector.Domain) from every axis in
            % the current DF. Reuses nexOp_computeREGOptions — same
            % co-indexed-pair registry and candidate logic mdlObj.refreshREG
            % uses — but with no single FTR-equivalent axis to derive from
            % (nexObject has no unified "feature axis" concept the way
            % mdlObject does), every axis is offered as a candidate input;
            % nexOp_computeREGOptions unions in whichever co-indexed
            % partners are actually present regardless of which axis they
            % came from. No-op for any subclass that hasn't added a REG
            % key to collector.Domain.selKeys.
            try
                srcAx = nexObj.DF_postOp.ax;
            catch
                return;
            end
            if ~isfield(nexObj.collector, 'Domain') || isempty(nexObj.collector.Domain)
                return;
            end
            bus = nexObj.collector.Domain;
            if ~isfield(bus.selKeys, 'REG'), return; end
            axNames = string(fieldnames(srcAx))';
            regOpts = nexOp_computeREGOptions(axNames, srcAx);
            bus.selKeys.REG = regOpts;
            if isfield(bus.listBoxes, 'REG') && ~isempty(bus.listBoxes.REG) ...
                    && isvalid(bus.listBoxes.REG)
                lb = bus.listBoxes.REG;
                lb.String = cellstr(regOpts);
                curIdx = find(string(regOpts) == string(nexObj.domain.REG), 1);
                if isempty(curIdx)
                    nexObj.domain.REG = "None";
                    lb.Value = 1;
                else
                    lb.Value = curIdx;
                end
            end
        end

        function onREGChanged(nexObj, lb)
            % Wire a REG listbox's Callback to this, same pattern as
            % onD1Changed/onANIChanged above — any subclass that adds a
            % REG key to its own collector.Domain can reuse this directly.
            if ~isfield(nexObj.collector.Domain.selKeys, 'REG'), return; end
            regOpts = nexObj.collector.Domain.selKeys.REG;
            if isempty(lb.Value) || isempty(regOpts), return; end
            nexObj.collector.Domain.selections.REG = lb.Value;
            nexObj.domain.REG = string(regOpts(lb.Value(end)));
        end

        function clearAnimatePointer(nexObj)
            % Free the animate axis's Pointer bus selection so its frame is driven
            % by ptr.value (advanced by stepAnimate), not pinned by a single bus
            % index. Slice consumers (nexOp_sliceAndCollapse) lock a residual axis
            % to its bus index when one is set; every Pointer key defaults to [1],
            % which would freeze the animation on frame 1.
            ax = char(string(nexObj.domain.animate));
            if isempty(ax), return; end
            try
                P = nexObj.collector.Pointer;
                if isempty(P) || ~isfield(P.selections, ax), return; end
                P.selections.(ax) = [];
                if isfield(P.listBoxes, ax) && ~isempty(P.listBoxes.(ax)) ...
                        && isvalid(P.listBoxes.(ax))
                    try, P.listBoxes.(ax).Value = []; catch, end
                end
            catch
            end
        end

        % -- POOLING -------------------------------------------------------
        function poolDF(nexObj)
            % Source must be the frozen raw DF, never DF_postOp, so repeated
            % calls don't compound pooling on already-pooled data.
            if isempty(nexObj.DF) || isempty(nexObj.DF_postOp), return; end
            ptr       = nexObj.DF_postOp.ptr;
            DF_pooled = nexOp_poolAxes(nexObj.pMap, nexObj.DF, ptr);
            nexObj.DF_postOp.df = DF_pooled.df;
            nexObj.DF_postOp.ax = DF_pooled.ax;
        end

        % ── Player ────────────────────────────────────────────────────────
        function startPlayer(nexObj)
            % Value==1 = pressed (play), Value==0 = released (stop).
            if nexObj.Figure.playButton.Value
                if strcmp(nexObj.player.Running, 'off'), nexObj.player.start; end
            else
                nexObj.player.stop;
            end
        end

        function stepAnimate(nexObj, args)
            % CFG HEADER
            stride = args.stride; % default = 1
            len_afterImage = args.len_afterImage; % default = 10
            trail_brightness = args.trail_brightness; % default = 2
            % Advance the animation pointer by stride steps along domain.animate,
            % then call visualize(). Inherited by all nexObject subclasses.
            axSel = nexObj.domain.animate;
            if isempty(axSel) || strlength(string(axSel)) == 0, return; end
            axSel = char(axSel);
            ptrObj = nexObj.DF_postOp.ptr;
            hasAx = (isobject(ptrObj) && isprop(ptrObj, axSel)) || ...
                    (isstruct(ptrObj) && isfield(ptrObj, axSel));
            if ~hasAx, return; end

            nAx = numel(nexObj.DF_postOp.ax.(axSel));
            if nAx < 1, return; end

            curVal = nexObj.DF_postOp.ptr.(axSel).value;

            % Multi-value Pointer selection → step through it as a sequence.
            % Single selection (incl. default [1]) falls through to range stepping
            % so the frame actually advances rather than being pinned.
            if isfield(nexObj.collector, 'Pointer') && ~isempty(nexObj.collector.Pointer) ...
                    && isfield(nexObj.collector.Pointer.selections, axSel)
                sel = nexObj.collector.Pointer.selections.(axSel);
                if numel(sel) > 1
                    curPos = find(sel == curVal, 1);
                    if isempty(curPos), curPos = 1 - stride; end
                    axVal = sel(mod(curPos - 1 + stride, numel(sel)) + 1);
                else
                    r    = nexObj.DF_postOp.ptr.(axSel).range;
                    span = r(2) - r(1) + 1;
                    if span < 1 || r(1) < 1 || r(2) > nAx
                        r = [1, nAx]; span = nAx;
                    end
                    axVal = r(1) + mod(curVal - r(1) + stride, span);
                end
            else
                r    = nexObj.DF_postOp.ptr.(axSel).range;
                span = r(2) - r(1) + 1;
                if span < 1 || r(1) < 1 || r(2) > nAx
                    r = [1, nAx]; span = nAx;
                end
                axVal = r(1) + mod(curVal - r(1) + stride, span);
            end
            axVal = max(1, min(nAx, axVal));
            nexObj.DF_postOp.ptr.(axSel).value   = axVal;
            nexObj.DF_postOp.ptr.(axSel).indices = axVal;
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

        function compileSTAT(nexObj, withinSubject)
            % Compile STAT from Parent categorical using current selections.
            % Requires nexObj.dfID_source to be a real data ID (not a placeholder).
            % withinSubject (optional): passed through to nexOp_compileSTAT's
            % own REG-canonicalization scope — omit/leave empty to use its
            % default (true, per-subject).
            if nargin < 2, withinSubject = []; end
            if isempty(nexObj.Parent) || ~strcmp(nexObj.Parent.classID, 'ctg') ...
                    || isempty(nexObj.dfID_source)
                return;
            end
            S_cat   = nex_returnSelectionMask(nexObj.Parent.selectionBus.categories);
            S_items = nex_returnSelectionMask(nexObj.Parent.selectionBus.items);
            try
                nexObj.STAT = nexOp_compileSTAT(nexObj, nexObj.dfID_source, S_cat, S_items, [], [], withinSubject);
            catch e
                disp(getReport(e));
            end
        end

        function initCollectorView(nexObj)
            % Initialise collector.View (CTG / VW / CLR / SRC).
            % Reads grouping keys from the CTG parent's selectionBus — no
            % compileSTAT required. Falls back to STAT columns when no CTG
            % parent is available (legacy / standalone objects).
            % ax-- entries are excluded from grpKeys: they are ptr filters,
            % not grouping columns, and never appear as STAT table columns.
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","sem","fitSentinel","W","ax_W","ptr_W"];
            grpKeys = "";
            ctgResolved = false;
            if ~isempty(nexObj.Parent) && isvalid(nexObj.Parent) && ...
                    strcmp(nexObj.Parent.classID, 'ctg') && ...
                    isfield(nexObj.Parent.selectionBus, 'categories')
                try
                    S_cat   = nex_returnSelectionMask(nexObj.Parent.selectionBus.categories);
                    catVals = string(struct2cell(S_cat))';
                    % keep only non-empty, non-None, non-ax-- entries
                    catVals = catVals( catVals ~= "" & ...
                                       ~strcmp(catVals,"None") & ...
                                       ~startsWith(catVals,"ax--") );
                    if ~isempty(catVals)
                        grpKeys = strrep(catVals, "--", "_");
                    end
                    ctgResolved = true;
                catch
                end
            end
            if ~ctgResolved && ~isempty(nexObj.STAT) && istable(nexObj.STAT)
                allCols = string(nexObj.STAT.Properties.VariableNames)';
                grpKeys = allCols(~ismember(allCols, DF_STRUCT_FIELDS));
                if isempty(grpKeys), grpKeys = ""; end
            end
            % Append ax--<field> entries so CLR can color by pointer axis value.
            % Stored as ax--X in CLR; resolveGroupColors translates to ax_X for
            % RESULTS table lookup and passes bare X to nexOp_resolveGroupColors
            % so atlas registry (dropout, chans) resolves correctly.
            axClrKeys = string.empty;
            try
                if ~isempty(nexObj.DF_postOp) && ~isempty(nexObj.DF_postOp.ax)
                    axClrKeys = "ax--" + string(fieldnames(nexObj.DF_postOp.ax))';
                end
            catch
            end
            clrKeys = [grpKeys(:); axClrKeys(:)];
            clrKeys = clrKeys(clrKeys ~= "");
            if isempty(clrKeys), clrKeys = ""; end

            viewDict.SRC = "DTS";
            viewDict.CTG = grpKeys;
            viewDict.VW  = nexObj.getCTGGroupKeys();
            viewDict.CLR = clrKeys;
            nexObj.collector.View = nexInit_collectorView(nexObj, viewDict);

            nexObj.wireCTGListeners();
        end

        function resID = buildResultID(nexObj, resType, nBins)
            % Build canonical result ID from the active CTG selection + params.
            % Format: res--<type>_ctg--<k1>-x-<k2>..._nBins--<n>_event--<ev>
            % Continuous grouping columns that will be quantile-binned carry ~g.
            % _event-- segment is appended when SLRT event alignment is active.
            if nargin < 2 || isempty(resType), resType = "AVG"; end
            if nargin < 3 || isempty(nBins),   nBins   = 4;     end
            try
                viewSel = nex_returnSelectionMask(nexObj.collector.View);
                active  = string(viewSel.CTG);
                active  = active(active ~= "" & ~strcmp(active, "None"));
            catch
                active = string.empty;
            end
            if ~isempty(nexObj.STAT) && istable(nexObj.STAT) && ~isempty(active)
                for k = 1:numel(active)
                    col = char(active(k));
                    if ismember(col, nexObj.STAT.Properties.VariableNames)
                        raw = nexObj.STAT.(col);
                        if isnumeric(raw) && nexOp_isContinuousVar(raw) && ...
                                numel(unique(raw(~isnan(raw)))) > nBins
                            active(k) = active(k) + "~g";
                        end
                    end
                end
            end
            if isempty(active)
                ctgStr = "none";
            else
                ctgStr = strjoin(active, "-x-");
            end
            resID = sprintf("res--%s_ctg--%s_nBins--%d", resType, ctgStr, nBins);
            try
                S_slrt       = nex_returnSelectionMask( ...
                    nexObj.nexon.console.SLRT.signals.eventAlignmentSelection);
                alignColTags = split(string(S_slrt.events), "_");
                eventTag     = string(alignColTags(1));
                if ~isempty(eventTag) && eventTag ~= ""
                    resID = resID + sprintf("_event--%s", eventTag);
                end
            catch
            end
        end

        function broadcastResult(nexObj, resID)
            % Copy result to all categorical siblings with matching dfID_source
            % and refresh their SRC bus so they see the new result immediately.
            if isempty(nexObj.Parent) || ~isvalid(nexObj.Parent) || ...
               ~strcmp(nexObj.Parent.classID, 'ctg') || ...
               ~isstruct(nexObj.Parent.Children) || ...
               ~isfield(nexObj.RESULTS, resID)
                return;
            end
            sibFields = fieldnames(nexObj.Parent.Children);
            for k = 1:numel(sibFields)
                sib = nexObj.Parent.Children.(sibFields{k});
                try
                    if ~isvalid(sib) || isequal(sib, nexObj), continue; end
                    if ~strcmp(sib.dfID_source, nexObj.dfID_source), continue; end
                    sib.RESULTS.(resID) = nexObj.RESULTS.(resID);
                    sib.refreshSRC();
                catch
                end
            end
        end

        function reportAverage(nexObj, resultID, nBins, STAT)
            % Group STAT by CTG bus selection, average per group, store in RESULTS.
            % Auto-compiles STAT when parent is a categorical and none is supplied.
            % resultID auto-generated via buildResultID when omitted.
            % nBins controls quantile binning for continuous columns (default 4).
            if nargin < 3 || isempty(nBins), nBins = 4; end
            if nargin < 4 || isempty(STAT)
                if ~isempty(nexObj.Parent) && isvalid(nexObj.Parent) && ...
                        strcmp(nexObj.Parent.classID, 'ctg')
                    % Gate REG canonicalization scope on whether subject is
                    % itself one of THIS report's CTG grouping columns: when
                    % it is, every group below is subject-pure by
                    % construction, so per-subject canonicalization
                    % (withinSubject=true) keeps each subject's own REG
                    % identity correct; when it isn't, groups are meant to
                    % span subjects (e.g. "average this channel across
                    % every subject/session"), so one global
                    % canonicalization pass (withinSubject=false) is what
                    % makes that pooling meaningful. Either way, every DF
                    % landing in one group below already shares one
                    % canonical layout, which is what keeps the group
                    % averaging step's positional trim (nexOp_trimTF) safe
                    % without needing to be REG-aware itself.
                    viewSel0 = nex_returnSelectionMask(nexObj.collector.View);
                    withinSubject = ismember("sessionLabel_subj", string(viewSel0.CTG));
                    nexObj.compileSTAT(withinSubject);
                end
                STAT = nexObj.STAT;
            end
            if nargin < 2 || isempty(resultID)
                displayLabel = nexObj.buildResultID("AVG", nBins);
                resultID     = nexObj.getResultKey(displayLabel);
                nexObj.resultLabels.(resultID) = char(displayLabel);
            end

            if isempty(STAT) || ~istable(STAT)
                fprintf('[%s.reportAverage] STAT is empty — call compileSTAT() first.\n', class(nexObj));
                return;
            end

            viewSel   = nex_returnSelectionMask(nexObj.collector.View);
            groupCols = string(viewSel.CTG);
            statCols  = string(STAT.Properties.VariableNames);
            groupCols = groupCols(groupCols ~= "" & ismember(groupCols, statCols));
            if isempty(groupCols)
                fprintf('[%s.reportAverage] No CTG columns selected.\n', class(nexObj));
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

            nexObj.refreshSRC();
            nexObj.refreshVW();
            nexObj.refreshCLR();
            nexObj.broadcastResult(resultID);

            try
                if ismember('h5_path', nexObj.nexon.console.BASE.DTS.Properties.VariableNames)
                    nexOp_saveResult(nexObj, resultID);
                end
            catch ME
                warning('[%s.reportAverage] auto-save failed: %s', class(nexObj), ME.message);
            end

            fprintf('[%s.reportAverage] %d groups → RESULTS.%s\n', class(nexObj), sum(valid), resultID);

            if ismethod(nexObj, 'visualize')
                nexObj.visualize();
            end
        end

        function reportAverage_batched(nexObj, resultID, nBins)
            % Disk-friendly reportAverage: loads one sessionLabel batch at a
            % time, sub-groups within each batch by h5-- keys, averages per
            % sub-group, and stores all groups in RESULTS.(resultID).
            %
            % sessionLabel-- keys → batch boundary (DTS only, no HDF5 reads).
            % h5--           keys → within-batch sub-grouping.  All h5 scalar
            %                       values are read once before the batch loop
            %                       so quantile bins are standardized globally.
            % ax--           keys → ptr filter for hyperslab reads.
            %
            %   nexObj.reportAverage_batched()
            %   nexObj.reportAverage_batched('avg1')
            %   nexObj.reportAverage_batched('avg1', nBins)
            if nargin < 3 || isempty(nBins), nBins = 4; end
            if nargin < 2 || isempty(resultID)
                displayLabel = nexObj.buildResultID("AVG", nBins);
                resultID     = nexObj.getResultKey(displayLabel);
                nexObj.resultLabels.(resultID) = char(displayLabel);
            end

            nexon = nexObj.nexon;
            DTS   = nexon.console.BASE.DTS;
            dfID  = nexObj.dfID_source;

            % ── Global filter (averagingSelection) ────────────────────────
            S_global = nex_returnSelectionMask(nexon.console.BASE.controlPanel.averagingSelection);
            idxSel   = nex_applySelectionMask(DTS, S_global);

            % ── CTG selection buses ───────────────────────────────────────
            if isempty(nexObj.Parent) || ~strcmp(nexObj.Parent.classID,'ctg')
                fprintf('[%s.reportAverage_batched] requires a CTG Parent.\n', class(nexObj));
                return;
            end
            S_cat     = nex_returnSelectionMask(nexObj.Parent.selectionBus.categories);
            S_items   = nex_returnSelectionMask(nexObj.Parent.selectionBus.items);
            catFields = fieldnames(S_cat);

            % ── sessionLabel item filter (DTS only, no HDF5) ─────────────
            nRows  = height(DTS);
            slMask = true(nRows, 1);
            for ci = 1:numel(catFields)
                catVal = string(S_cat.(catFields{ci}));
                if ~startsWith(catVal, 'sessionLabel--')
                    continue
                end
                fieldName = char(extractAfter(catVal, 'sessionLabel--'));
                itemSel   = S_items.(catFields{ci});
                if isempty(itemSel) || all(strcmp(string(itemSel), 'None'))
                    continue
                end
                colVals = convertCharsToStrings( ...
                    arrayfun(@(x) parseSessionLabel(x, fieldName), ...
                             DTS.sessionLabel, 'UniformOutput', true));
                slMask = slMask & ismember(colVals, string(itemSel));
            end
            rowIdx = find(idxSel & slMask);
            if isempty(rowIdx)
                fprintf('[%s.reportAverage_batched] no trials selected.\n', class(nexObj));
                return;
            end

            % ── ptr filter from ax-- selections ───────────────────────────
            ptr_filter = nexOp_buildPtrFromAxSel(S_cat, S_items, nexObj);

            % ── Grouping keys from View.CTG ───────────────────────────────
            viewSel = nex_returnSelectionMask(nexObj.collector.View);
            grpKeys = string(viewSel.CTG);
            grpKeys = grpKeys(grpKeys ~= "" & grpKeys ~= "None");
            slKeys  = grpKeys(startsWith(grpKeys, 'sessionLabel_'));

            % ── Identify h5-- fields ──────────────────────────────────────
            h5CatFields = {};   % slot names in S_cat
            h5CatIDs    = {};   % full "h5--X" strings
            h5Keys_grp  = strings(0,1);  % "h5_X" keys that are also in grpKeys
            for ci = 1:numel(catFields)
                catVal = string(S_cat.(catFields{ci}));
                if ~startsWith(catVal, 'h5--')
                    continue
                end
                h5CatFields{end+1} = catFields{ci};
                h5CatIDs{end+1}    = char(catVal);
                h5Key = strrep(catVal, '--', '_');
                if ismember(h5Key, grpKeys)
                    h5Keys_grp(end+1) = h5Key;
                end
            end

            % ── Pre-read all h5 scalars for rowIdx (one pass, before batching)
            %    Apply item filter globally, then bin once for standardized
            %    quantiles across all batches. ──────────────────────────────
            h5AllTable = table();
            for hi = 1:numel(h5CatFields)
                h5Key = char(strrep(string(h5CatIDs{hi}), '--', '_'));
                h5AllTable.(h5Key) = string( ...
                    dtsIO_readTF_category(nexon, h5CatIDs{hi}, rowIdx));
            end

            if width(h5AllTable) > 0
                % Item filter
                h5ItemMask = true(numel(rowIdx), 1);
                for hi = 1:numel(h5CatFields)
                    h5Key   = char(strrep(string(h5CatIDs{hi}), '--', '_'));
                    itemSel = S_items.(h5CatFields{hi});
                    if isempty(itemSel) || all(strcmp(string(itemSel), 'None'))
                        continue
                    end
                    h5ItemMask = h5ItemMask & ismember(h5AllTable.(h5Key), string(itemSel));
                end
                rowIdx     = rowIdx(h5ItemMask);
                h5AllTable = h5AllTable(h5ItemMask, :);
                if isempty(rowIdx)
                    fprintf('[%s.reportAverage_batched] no trials after h5 filter.\n', class(nexObj));
                    return;
                end
                % Global bin labels for grp keys — standardized across batches
                if ~isempty(h5Keys_grp)
                    grpCols      = intersect(cellstr(h5Keys_grp), ...
                                             h5AllTable.Properties.VariableNames, 'stable');
                    h5LabelTable = nexOp_binContinuousVars(h5AllTable(:, grpCols), h5Keys_grp, nBins);
                else
                    h5LabelTable = table();
                end
            else
                h5LabelTable = table();
            end

            % ── Build sessionLabel batch groups from (h5-filtered) rowIdx ─
            if isempty(slKeys)
                batchLabels = table();
                batchGroups = {rowIdx};
            else
                batchTable = table();
                for ki = 1:numel(slKeys)
                    fieldName = char(extractAfter(slKeys(ki), 'sessionLabel_'));
                    batchTable.(char(slKeys(ki))) = convertCharsToStrings( ...
                        arrayfun(@(x) parseSessionLabel(x, fieldName), ...
                                 DTS.sessionLabel(rowIdx), 'UniformOutput', true));
                end
                batchTable  = nexOp_binContinuousVars(batchTable, slKeys, nBins);
                [G, batchLabels] = findgroups(batchTable);
                nBatch      = height(batchLabels);
                batchGroups = arrayfun(@(b) rowIdx(G == b), 1:nBatch, 'UniformOutput', false);
            end

            % ── Per-batch: load → h5 sub-group → average ─────────────────
            nBatch    = numel(batchGroups);
            df_out    = {};  ax_out    = {};
            ptr_out   = {};  sem_out   = {};
            rowLabels = {};

            t_preBuff = [];
            try
                if isfield(nexon.console.BASE.UserData, 'preBuffLen')
                    t_preBuff = nexon.console.BASE.UserData.preBuffLen;
                end
            catch, end

            for b = 1:nBatch
                bIdx = batchGroups{b};
                fprintf('[%s.reportAverage_batched] batch %d/%d  (%d trials)\n', ...
                        class(nexObj), b, nBatch, numel(bIdx));

                % Sub-group within this batch using pre-computed global h5 labels
                if width(h5LabelTable) > 0
                    [~, posInRowIdx] = ismember(bIdx, rowIdx);
                    h5SubTable = h5LabelTable(posInRowIdx, :);
                    [G_sub, subLabels] = findgroups(h5SubTable);
                else
                    G_sub     = ones(numel(bIdx), 1);
                    subLabels = table();
                end

                % Welford online accumulation per sub-group (O(shape) memory)
                for sg = 1:max(G_sub)
                    sgIdx = bIdx(G_sub == sg);
                    [mean_df, sem_df, ax_ref, n] = nexOp_accumulateTF( ...
                        nexon, sgIdx, dfID, ptr_filter, t_preBuff);
                    if n == 0 || isempty(mean_df)
                        continue;
                    end
                    ptr_sg         = nexInit_axisPointer(mean_df, ax_ref);
                    df_out{end+1}  = mean_df;    ax_out{end+1}  = ax_ref;
                    ptr_out{end+1} = ptr_sg;     sem_out{end+1} = sem_df;
                    lbl = table();
                    if ~isempty(batchLabels)
                        lbl = [lbl, batchLabels(b,:)];
                    end
                    if ~isempty(subLabels)
                        lbl = [lbl, subLabels(sg,:)];
                    end
                    rowLabels{end+1} = lbl;
                end
            end
            if isempty(df_out)
                return;
            end

            % ── Assemble RESULT table ─────────────────────────────────────
            RESULT = table(df_out(:), ax_out(:), ptr_out(:), sem_out(:), ...
                           'VariableNames', {'df','ax','ptr','sem'});
            if ~isempty(rowLabels)
                RESULT = [RESULT, cat(1, rowLabels{:})];
            end
            nexObj.RESULTS.(resultID) = RESULT;

            nexObj.refreshSRC();
            nexObj.refreshVW();
            nexObj.refreshCLR();
            nexObj.broadcastResult(resultID);
            fprintf('[%s.reportAverage_batched] %d groups → RESULTS.%s\n', ...
                    class(nexObj), numel(df_out), resultID);

            try
                if ismember('h5_path', nexon.console.BASE.DTS.Properties.VariableNames)
                    nexOp_saveResult(nexObj, resultID);
                end
            catch ME
                warning('[%s.reportAverage_batched] auto-save failed: %s', class(nexObj), ME.message);
            end

            if ismethod(nexObj, 'visualize')
                nexObj.visualize();
            end
        end

        function loadResult(nexObj, resultID)
            % Load a saved RESULTS entry from nexRESULTS.h5 into nexObj.RESULTS
            % and update the SRC bus.
            %
            %   nexObj.loadResult('avg1')
            [T, displayLabel] = nexOp_loadResult(nexObj, resultID);
            nexObj.RESULTS.(resultID) = T;
            if ~isempty(displayLabel)
                nexObj.resultLabels.(resultID) = displayLabel;
            end
            nexObj.refreshSRC();
            nexObj.refreshVW();
            fprintf('[%s.loadResult] %d rows ← RESULTS.%s\n', class(nexObj), height(T), resultID);
        end

        function discoverResults(nexObj)
            % Scan nexRESULTS.h5 and register stubs for results not yet known.
            % Stubs (RESULTS.(id) = []) populate the SRC dropdown immediately
            % without loading data — actual rows are loaded lazily on first
            % selection via applySRC.
            try
                h5Dir  = fileparts(char(nexObj.nexon.console.BASE.DTS.h5_path(1)));
                h5File = fullfile(h5Dir, 'nexRESULTS.h5');
                if ~isfile(h5File), return; end
                fapl = H5P.create('H5P_FILE_ACCESS');
                H5P.set_fclose_degree(fapl, 'H5F_CLOSE_STRONG');
                fid  = H5F.open(h5File, 'H5F_ACC_RDONLY', fapl);
                H5P.close(fapl);
                info    = H5G.get_info(fid);
                nGroups = double(info.nlinks);
                resultIDs = cell(1, nGroups);
                for gi = 0:nGroups-1
                    resultIDs{gi+1} = H5L.get_name_by_idx(fid, '/', ...
                        'H5_INDEX_NAME', 'H5_ITER_INC', gi, 'H5P_DEFAULT');
                end
                H5F.close(fid);
            catch ME
                warning('[%s.discoverResults] scan failed: %s', class(nexObj), ME.message);
                return;
            end
            anyNew = false;
            myDFID = char(nexObj.dfID_source);
            for gi = 1:numel(resultIDs)
                rID = resultIDs{gi};
                if isfield(nexObj.RESULTS, rID), continue; end
                % Filter by dfID_source — skip results with no tag or wrong tag.
                try
                    savedDFID = h5read(h5File, ['/' rID '/meta/dfID_source']);
                    if iscell(savedDFID), savedDFID = savedDFID{1}; end
                    if ~isempty(myDFID) && ~strcmp(char(savedDFID), myDFID)
                        continue;
                    end
                catch
                    continue;   % no dfID_source tag → skip
                end
                % Register stub — data loaded on demand
                nexObj.RESULTS.(rID) = [];
                % Read display label cheaply (single string dataset, no row data)
                try
                    labelPath = ['/' rID '/meta/displayLabel'];
                    dlabel = h5read(h5File, labelPath);
                    if iscell(dlabel), dlabel = dlabel{1}; end
                    nexObj.resultLabels.(rID) = char(dlabel);
                catch
                end
                anyNew = true;
            end
            if anyNew
                nexObj.refreshSRC();
            end
        end

        function importRESULTS(nexObj, srcRESULTS, resultID)
            % Import entries from another nexObject's RESULTS struct.
            %
            %   nexObj.importRESULTS(otherNexObj.RESULTS)
            %       Import all resultID keys from the source RESULTS struct.
            %
            %   nexObj.importRESULTS(otherNexObj.RESULTS, 'avg1')
            %       Import only the named key from the source RESULTS struct.
            %
            % The SRC dropdown is rebuilt and the last imported key is
            % selected and rendered immediately.

            if nargin < 3, resultID = ''; end

            if ~isstruct(srcRESULTS)
                fprintf('[%s.importRESULTS] srcRESULTS must be a RESULTS struct — nothing imported.\n', ...
                    class(nexObj));
                return;
            end

            if ~isempty(resultID)
                % Import one specific key
                if ~isfield(srcRESULTS, resultID)
                    fprintf('[%s.importRESULTS] key ''%s'' not found in source RESULTS.\n', ...
                        class(nexObj), resultID);
                    return;
                end
                nexObj.RESULTS.(resultID) = srcRESULTS.(resultID);
                importedKeys = {resultID};
            else
                % Import all table-valued keys
                srcFields    = fieldnames(srcRESULTS);
                importedKeys = srcFields(cellfun(@(k) istable(srcRESULTS.(k)), srcFields));
                if isempty(importedKeys)
                    fprintf('[%s.importRESULTS] source RESULTS has no table entries — nothing imported.\n', ...
                        class(nexObj));
                    return;
                end
                for ki = 1:numel(importedKeys)
                    nexObj.RESULTS.(importedKeys{ki}) = srcRESULTS.(importedKeys{ki});
                end
            end

            lastKey = importedKeys{end};
            fprintf('[%s.importRESULTS] imported {%s}\n', ...
                class(nexObj), strjoin(string(importedKeys)', ', '));

            % Rebuild SRC bus (display labels from resultLabels, struct keys in selKeys)
            nexObj.refreshSRC();

            nexObj.refreshCLR();
            nexObj.refreshVW();

            if ismethod(nexObj, 'visualize')
                nexObj.visualize();
            end
        end

        function srcKey = getCurrentSRC(nexObj)
            % Return the currently selected SRC key, or 'DTS' as fallback.
            try
                bus    = nexObj.collector.View;
                idx    = bus.selections.SRC;
                srcKey = char(bus.selKeys.SRC(idx(end)));
            catch
                srcKey = 'DTS';
            end
        end

        function vwKeys = getCTGGroupKeys(nexObj)
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","cov","sem","labels","fitSentinel","W","ax_W","ptr_W"];
            % Strip the "__W" weights-facet suffix refreshSRC/applySRC add
            % to selKeys.SRC — RESULTS itself is always keyed on the real
            % (unsuffixed) result ID. Without this, isfield() below always
            % fails for a weights-facet selection, VW silently comes back
            % "" for it, and nexVisualization_monoGram's useResults check
            % (which requires a non-empty VW) falls through to the
            % permanently-empty DF_postOp for a source-watching nexObject
            % — same stripping applySRC/nexVisualization_monoGram already
            % do, just missing here too.
            srcKey = erase(nexObj.getCurrentSRC(), "__W");
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

        function rowIdx = filterResultsByVW(nexObj, RESULT, vwLabels)
            % AND-filter RESULT rows by VW selection.
            % Buckets selected labels by which group column they belong to,
            % then requires each row to match in every constrained column.
            % Returns all row indices when vwLabels is empty.
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","cov","sem","labels","fitSentinel","W","ax_W","ptr_W"];
            allCols  = string(RESULT.Properties.VariableNames);
            grpCols  = allCols(~ismember(allCols, DF_STRUCT_FIELDS));
            vwLabels = string(vwLabels);
            vwLabels = vwLabels(vwLabels ~= "");
            if isempty(vwLabels) || isempty(grpCols)
                rowIdx = (1:height(RESULT))';
                return;
            end
            colSel = cell(numel(grpCols), 1);
            for ci = 1:numel(grpCols)
                uniq_ci    = unique(string(RESULT.(char(grpCols(ci)))));
                colSel{ci} = vwLabels(ismember(vwLabels, uniq_ci));
            end
            mask = true(height(RESULT), 1);
            for ci = 1:numel(grpCols)
                if isempty(colSel{ci})
                    continue;
                end
                mask = mask & ismember(string(RESULT.(char(grpCols(ci)))), colSel{ci});
            end
            rowIdx = find(mask);
            if isempty(rowIdx)
                rowIdx = (1:height(RESULT))'; 
            end
        end

        function refreshCLR(nexObj)
            % Rebuild CLR bus to include group columns from all current RESULTS tables.
            % Preserves existing ax-- keys and any prior selection that still exists.
            if ~isfield(nexObj.collector, 'View'), return; end
            bus = nexObj.collector.View;

            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","cov","sem","labels","fitSentinel","W","ax_W","ptr_W"];

            % Separate existing CLR keys into group keys and ax-- keys
            existing = string(bus.selKeys.CLR);
            existing = existing(existing ~= "");
            axKeys   = existing(startsWith(existing, "ax--"));
            grpKeys  = existing(~startsWith(existing, "ax--"));

            % Merge group columns from every RESULTS table
            resFields = fieldnames(nexObj.RESULTS);
            for ki = 1:numel(resFields)
                T = nexObj.RESULTS.(resFields{ki});
                if ~istable(T), continue; end
                cols    = string(T.Properties.VariableNames);
                newCols = cols(~ismember(cols, DF_STRUCT_FIELDS));
                grpKeys = union(grpKeys, newCols, 'stable');
            end

            clrKeys = [grpKeys(:); axKeys(:)];
            clrKeys = clrKeys(clrKeys ~= "");
            if isempty(clrKeys), clrKeys = ""; end

            % Preserve selection indices that still exist in the new key list
            oldKeys = string(bus.selKeys.CLR);
            oldSel  = bus.selections.CLR;
            if ~isempty(oldSel) && ~isempty(oldKeys) && ~isequal(oldKeys, "")
                validOld   = oldSel(oldSel >= 1 & oldSel <= numel(oldKeys));
                prevLabels = oldKeys(validOld);
                newSel     = find(ismember(clrKeys, prevLabels))';
            else
                newSel = [];
            end

            bus.selKeys.CLR    = clrKeys;
            bus.selections.CLR = newSel;
            if isfield(bus.listBoxes, 'CLR') && ~isempty(bus.listBoxes.CLR) ...
                    && isvalid(bus.listBoxes.CLR)
                bus.listBoxes.CLR.String = clrKeys;
                bus.listBoxes.CLR.Max    = max(1, numel(clrKeys));
                bus.listBoxes.CLR.Value  = newSel;
            end
        end

        function refreshVW(nexObj)
            % Update VW selectionBus from current RESULTS source.
            % Preserves previously selected labels when they still exist in the
            % new key set (e.g. switching between RESULTS with shared labels).
            % Falls back to all-selected only when nothing carries over.
            % Subclasses that need structural side-effects (e.g. rebuildTrackers)
            % should override and call refreshVW@nexObject(nexObj) first.
            if ~isfield(nexObj.collector, 'View') 
                return;
            end
            newKeys = nexObj.getCTGGroupKeys();
            bus     = nexObj.collector.View;
            nVW     = numel(newKeys);

            oldKeys = bus.selKeys.VW;
            oldSel  = bus.selections.VW;
            if ~isempty(oldKeys) && ~isempty(oldSel) && ~isequal(oldKeys, "")
                validOld   = oldSel(oldSel >= 1 & oldSel <= numel(oldKeys));
                prevLabels = string(oldKeys(validOld));
                newSel     = find(ismember(newKeys, prevLabels))';
                if isempty(newSel)
                    newSel = 1:nVW; 
                end
            else
                newSel = 1:nVW;
            end

            bus.selKeys.VW    = newKeys;
            bus.selections.VW = newSel;
            if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW) ...
                    && isvalid(bus.listBoxes.VW)
                bus.listBoxes.VW.String = newKeys;
                bus.listBoxes.VW.Max    = nVW;
                bus.listBoxes.VW.Value  = newSel;
            end
        end

        function refreshCTG(nexObj)
            % Update CTG selectionBus from current parent categorical's categories.
            % Preserves previously selected labels that still exist in the new key set.
            % Parallel to refreshVW — called automatically via PostSet listener on
            % Parent.selectionBus.categories.selections.
            if ~isfield(nexObj.collector, 'View'), return; end
            if isempty(nexObj.Parent) || ~isvalid(nexObj.Parent) || ...
               ~strcmp(nexObj.Parent.classID, 'ctg') || ...
               ~isfield(nexObj.Parent.selectionBus, 'categories')
                return;
            end
            try
                S_cat   = nex_returnSelectionMask(nexObj.Parent.selectionBus.categories);
                catVals = string(struct2cell(S_cat))';
                catVals = catVals(catVals ~= "" & ~strcmp(catVals,"None") & ~startsWith(catVals,"ax--"));
                newKeys = strrep(catVals, "--", "_");
                if isempty(newKeys), newKeys = ""; end
            catch
                return;
            end
            bus  = nexObj.collector.View;
            nCTG = numel(newKeys);
            oldKeys = bus.selKeys.CTG;
            oldSel  = bus.selections.CTG;
            if ~isempty(oldKeys) && ~isempty(oldSel) && ~isequal(oldKeys, "")
                validOld   = oldSel(oldSel >= 1 & oldSel <= numel(oldKeys));
                prevLabels = string(oldKeys(validOld));
                newSel     = find(ismember(newKeys, prevLabels))';
                if isempty(newSel), newSel = 1:nCTG; end
            else
                newSel = 1:nCTG;
            end
            bus.selKeys.CTG    = newKeys;
            bus.selections.CTG = newSel;
            if isfield(bus.listBoxes, 'CTG') && ~isempty(bus.listBoxes.CTG) ...
                    && isvalid(bus.listBoxes.CTG)
                bus.listBoxes.CTG.String = newKeys;
                bus.listBoxes.CTG.Max    = nCTG;
                bus.listBoxes.CTG.Value  = newSel;
            end
        end

        function refreshCTGFromAVG(nexObj)
            % Set CTG bus to the grouping columns of nexObj.AVG (the active RESULT).
            % Called when SRC changes to a RESULT so the visualization mask can
            % map VW group labels (values) to the correct column (e.g. "stimSite").
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","sem","cov","labels", ...
                                 "trialNumber","sampleNumber","fitSentinel","W","ax_W","ptr_W"];
            tbl = nexObj.AVG;
            if isempty(tbl) || ~istable(tbl)
                nexObj.refreshCTG(); return;
            end
            cols    = string(tbl.Properties.VariableNames)';
            grpCols = cols(~ismember(cols, DF_STRUCT_FIELDS));
            if isempty(grpCols), grpCols = ""; end
            bus  = nexObj.collector.View;
            nCTG = numel(grpCols);
            bus.selKeys.CTG    = grpCols;
            bus.selections.CTG = 1:nCTG;
            if isfield(bus.listBoxes, 'CTG') && ~isempty(bus.listBoxes.CTG) ...
                    && isvalid(bus.listBoxes.CTG)
                bus.listBoxes.CTG.String = grpCols;
                bus.listBoxes.CTG.Max    = max(1, nCTG);
                bus.listBoxes.CTG.Value  = 1:nCTG;
            end
        end

        function wireCTGListeners(nexObj)
            % Attach PostSet listeners so category/item changes in the parent
            % categorical propagate to this nexObject's CTG listbox via refreshCTG.
            % Safe to call multiple times — skips if listeners already exist.
            if isempty(nexObj.Parent) || ~isvalid(nexObj.Parent) || ...
                    ~strcmp(nexObj.Parent.classID, 'ctg') || ...
                    ~isfield(nexObj.Parent.selectionBus, 'categories')
                return;
            end
            if ~isfield(nexObj.Listeners, 'ctgCategories') || ...
                    isempty(nexObj.Listeners.ctgCategories)
                nexObj.Listeners.ctgCategories = addlistener(...
                    nexObj.Parent.selectionBus.categories, 'selections', 'PostSet', ...
                    @(~,~) nexObj.refreshCTG());
            end
            if isfield(nexObj.Parent.selectionBus, 'items') && ...
                    (~isfield(nexObj.Listeners, 'ctgItems') || ...
                     isempty(nexObj.Listeners.ctgItems))
                nexObj.Listeners.ctgItems = addlistener(...
                    nexObj.Parent.selectionBus.items, 'selections', 'PostSet', ...
                    @(~,~) nexObj.refreshCTG());
            end
        end

        function refreshSRC(nexObj)
            % Rebuild SRC selKeys as one entry per (RESULTS-key x faculty)
            % pair actually present, BLOCKED by faculty (every accuracy
            % entry, then every weights entry) rather than interleaved per
            % key — sweeping CTG-combo rows for weights vs for scores
            % stays visually separate instead of alternating. selKeys.SRC
            % holds the REAL lookup key (suffixed "__W" for the weights
            % facet — see applySRC, which parses it back off); the listbox
            % shows a human label instead (resultLabels when available,
            % plus " · weights" for the weights block). Degrades to
            % exactly today's behavior for any RESULTS table with no W
            % column at all — the weights block is simply empty then.
            if ~isfield(nexObj.collector, 'View'), return; end
            bus        = nexObj.collector.View;
            baseKey    = bus.selKeys.SRC(1);
            resultKeys = string(fieldnames(nexObj.RESULTS));

            accKeys = string.empty(1,0); accLbls = string.empty(1,0);
            wKeys   = string.empty(1,0); wLbls   = string.empty(1,0);
            for i = 1:numel(resultKeys)
                k   = resultKeys(i);
                lbl = k;
                if isfield(nexObj.resultLabels, char(k))
                    lbl = string(nexObj.resultLabels.(char(k)));
                end
                accKeys(end+1) = k;   accLbls(end+1) = lbl; %#ok<AGROW>
                R = nexObj.RESULTS.(char(k));
                % Lazy stubs (R == []) are optimistically offered too —
                % real emptiness is only checkable once loaded, same
                % convention applySRC's own lazy-load already uses.
                if isempty(R) || (istable(R) && ismember('W', string(R.Properties.VariableNames)) ...
                        && any(~cellfun(@isempty, R.W)))
                    wKeys(end+1) = k + "__W";                 %#ok<AGROW>
                    wLbls(end+1) = lbl + " " + char(183) + " weights"; %#ok<AGROW>
                end
            end
            keys   = [baseKey; accKeys(:); wKeys(:)];
            labels = [baseKey; accLbls(:); wLbls(:)];

            bus.selKeys.SRC    = keys;
            bus.selections.SRC = numel(keys);
            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                    && isvalid(bus.listBoxes.SRC)
                bus.listBoxes.SRC.String = cellstr(labels);
                bus.listBoxes.SRC.Max    = 1;
                bus.listBoxes.SRC.Value  = numel(keys);
            end
        end

        function structKey = getResultKey(nexObj, displayLabel)
            % Derive a short, valid, deterministic struct key from a display label.
            % Format: res_<TYPE>_<8hexhash>  (always <= 20 chars, always valid).
            % The full human-readable label lives in resultLabels and the listbox.
            raw = char(displayLabel);
            tok = regexp(raw, '^res--(\w+)_', 'tokens', 'once');
            if ~isempty(tok)
                prefix = ['res_' tok{1} '_'];
            else
                prefix = 'res_';
            end
            hashVal   = mod(sum(double(raw) .* (1:numel(raw))), 2^32);
            structKey = sprintf('%s%08x', prefix, hashVal);
        end

        function displayLabel = getResultLabel(nexObj, structKey)
            % Look up the human-readable label for a RESULTS struct key.
            % Falls back to the struct key itself when no label is stored.
            structKey = char(structKey);
            if isfield(nexObj.resultLabels, structKey)
                displayLabel = nexObj.resultLabels.(structKey);
            else
                displayLabel = structKey;
            end
        end

        function onSRCChanged(nexObj, lb)
            nexObj.collector.View.selections.SRC = lb.Value;
            % Read struct key from selKeys (not from lb.String which shows labels)
            idx    = lb.Value(end);
            srcKey = char(nexObj.collector.View.selKeys.SRC(idx));
            nexObj.applySRC(srcKey);
            if ismethod(nexObj, 'visualize')
                nexObj.visualize();
            end
        end

        function applySRC(nexObj, srcKey)
            % Update the SRC bus selection and refresh the VW bus, then
            % re-point Domain/Pointer to whichever axis shape is now
            % active. Stubs (RESULTS.(key) = []) are lazily loaded on
            % first selection.
            %
            % srcKey may carry the "__W" facet suffix refreshSRC adds for
            % the weights block — parsed off here (nexObj.viewFacet set
            % accordingly) before any RESULTS lookup, which always uses
            % the real (stripped) key. The SRC selection-INDEX lookup,
            % though, stays keyed on the ORIGINAL (possibly suffixed)
            % srcKey — searching selKeys.SRC for the stripped key instead
            % would silently re-select the accuracy row even when weights
            % was actually clicked, since both exist as separate entries.
            %
            % Deliberately does NOT call visualize() itself — onSRCChanged
            % already does, gated by ismethod — calling it again here
            % would double-render for every subclass using this base
            % version unchanged.
            srcKey  = string(srcKey);
            isW     = endsWith(srcKey, "__W");
            realKey = char(erase(srcKey, "__W"));
            nexObj.viewFacet = "accuracy";
            if isW, nexObj.viewFacet = "weights"; end

            if ~isfield(nexObj.collector, 'View')
                return;
            end
            if ~strcmp(realKey, 'DF') && ~strcmp(realKey, 'DTS') ...
                    && ~isfield(nexObj.RESULTS, realKey)
                return;
            end
            % Lazy-load stub on first selection. Two conventions, mutually
            % exclusive: a source-backed stub (registered by
            % wireModelSource, e.g. a live mdlObj) pulls straight from
            % nexObj.source.RESULTS — nexRESULTS.h5 was never involved and
            % nexObj.loadResult's disk path fails outright against it (no
            % such resultID on disk). A disk-backed stub (registered by
            % discoverResults) goes through loadResult as before. Ported
            % from nexObj_bar's own applySRC, which originated the
            % source-backed half of this — this base version previously
            % only had the disk half, which is why nexObj_monoGram (the
            % first subclass to use the base applySRC WITH a source) hit
            % an HDF5 "not a file ID" error selecting a source-backed
            % result.
            if isfield(nexObj.RESULTS, realKey) && isempty(nexObj.RESULTS.(realKey))
                if ~isempty(nexObj.source)
                    try
                        if ~isvalid(nexObj.source) || ~isfield(nexObj.source.RESULTS, realKey)
                            return;   % source gone, or result no longer there
                        end
                        nexObj.RESULTS.(realKey) = nexObj.source.RESULTS.(realKey);
                    catch
                        return;
                    end
                else
                    fprintf('[%s] loading %s ...\n', class(nexObj), nexObj.getResultLabel(realKey));
                    try
                        nexObj.loadResult(realKey);
                    catch ME
                        warning('[%s.applySRC] lazy load failed for %s: %s', ...
                            class(nexObj), realKey, ME.message);
                        return;
                    end
                end
            end
            bus  = nexObj.collector.View;
            idx  = find(string(bus.selKeys.SRC) == srcKey, 1);
            if isempty(idx)
                return;
            end
            bus.selections.SRC = idx;
            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                    && isvalid(bus.listBoxes.SRC)
                bus.listBoxes.SRC.Value = idx;
            end
            nexObj.refreshVW();

            % Re-point Domain/Pointer to whichever axis shape is now
            % active — raw DF for "DF"/"DTS", else the matched RESULTS
            % row's df-facet or W-facet axes (same VW row-matching
            % nexVisualization_monoGram's useResults branch — and
            % anything else built the same way — already uses). A no-op
            % for any nexObject without collector.Domain/Pointer at all
            % (both remodelDomain and rebuildPointerPanel are internally
            % gated), and for any RESULTS table with no ax_W column
            % (falls through to the df-facet axes regardless of
            % viewFacet).
            newAx = [];
            if strcmp(realKey, 'DF') || strcmp(realKey, 'DTS')
                try, newAx = nexObj.DF_postOp.ax; catch, end
            elseif isfield(nexObj.RESULTS, realKey) && ~isempty(nexObj.RESULTS.(realKey))
                RESULT = nexObj.RESULTS.(realKey);
                if istable(RESULT) && height(RESULT) > 0
                    viewSel  = nex_returnSelectionMask(nexObj.collector.View);
                    vwGroups = string(viewSel.VW);
                    matchingRows = nexObj.filterResultsByVW(RESULT, vwGroups);
                    if ~isempty(matchingRows)
                        % Union Pointer's candidate axis across EVERY
                        % currently-displayed (VW-matching) row — e.g. one
                        % row per subject from a subject-pure reportAverage
                        % grouping — instead of only the first matching
                        % row. Reading only matchingRows(1) here meant
                        % Pointer only ever offered whichever row happened
                        % to land first, hiding every value the OTHER
                        % displayed rows have that row doesn't. Each row's
                        % own rendering already only shows its own real
                        % data regardless (see nexVisualization_polyGraph's
                        % union-keepMask handling) — this only changes what
                        % Pointer OFFERS as selectable options.
                        newAx = struct();
                        for mi = 1:numel(matchingRows)
                            r = matchingRows(mi);
                            useW = strcmp(nexObj.viewFacet, "weights") && ...
                                   ismember('ax_W', string(RESULT.Properties.VariableNames)) && ...
                                   ~isempty(RESULT.ax_W{r});
                            if useW
                                axRow = RESULT.ax_W{r};
                            else
                                axRow = RESULT.ax{r};
                            end
                            if isempty(fieldnames(newAx))
                                newAx = axRow;
                                continue;
                            end
                            fn = fieldnames(axRow);
                            for fi = 1:numel(fn)
                                f = fn{fi};
                                if isfield(newAx, f)
                                    newAx.(f) = union(newAx.(f), axRow.(f));
                                else
                                    newAx.(f) = axRow.(f);
                                end
                            end
                        end
                    end
                end
            end
            if ~isempty(newAx) && ismethod(nexObj, 'remodelDomain')
                nexObj.remodelDomain(newAx);
                if ismethod(nexObj, 'rebuildPointerPanel')
                    nexObj.rebuildPointerPanel();
                end
            end
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
            if isempty(clrCols) || N == 0
                return;
            end

            gCols   = string(dataTable.Properties.VariableNames);
            C_lut   = {};
            C_hsv   = {};
            hsv_mod = {};

            for ci = 1:numel(clrCols)
                col = char(clrCols(ci));
                % ax--X keys: translate to bare axis name for table lookup and
                % color resolution (lets stateSpace G_sel columns work directly).
                bareKey = col;
                if startsWith(col, 'ax--')
                    bare = col(5:end);
                    if ~ismember(bare, gCols)
                        continue;
                    end
                    col     = bare;
                    bareKey = bare;
                end
                if ~ismember(col, gCols) 
                    continue;
                end
                [C_ci, matched] = nexOp_resolveGroupColors( ...
                    nexObj.nexon, bareKey, string(dataTable.(col)));
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

        function [C, labels] = resolveCLRColors(nexObj, DF, clrCols, nTraces, rowTable)
            % Unified per-trace color resolution for any mix of CLR key types.
            %
            %   ax--X keys  — resolve from DF.ax.(X) at Pointer bus selections;
            %                 one color entry per trace (1:nTraces clamped into
            %                 the selected indices).
            %   column keys — resolve one color from rowTable.(col) and broadcast
            %                 to all nTraces (categorical / group-level coloring).
            %
            % Both types feed the same two-pass blend as resolveGroupColors:
            %   Pass 1 — average all LUT/atlas-matched N×3 layers, normalise.
            %   Pass 2 — rotate hue/sat of unmatched layers on top of the LUT base.
            %
            % labels: axis-value strings from the first ax-- key that resolves,
            %   or empty when only group-column keys are active (caller uses its
            %   own row labels for the legend in that case).
            if nargin < 5, rowTable = table(); end
            GREEN  = nexObj.nexon.settings.Colors.cyberGreen;
            if ischar(GREEN) || isstring(GREEN)
                h = strrep(char(GREEN), '#', '');
                if numel(h) == 6
                    GREEN = [hex2dec(h(1:2)), hex2dec(h(3:4)), hex2dec(h(5:6))] / 255;
                else
                    GREEN = [0, 1, 0.25];
                end
            end
            C      = repmat(GREEN, nTraces, 1);
            labels = string.empty;
            if isempty(clrCols) || nTraces == 0, return; end

            grpCols = string(rowTable.Properties.VariableNames);
            ptrBus  = nexObj.collector.Pointer;
            all_C   = {};

            for ci = 1:numel(clrCols)
                key = char(clrCols(ci));
                if startsWith(key, 'ax--')
                    % ── Axis-value layer (per-trace) ──────────────────────
                    axField = key(5:end);
                    if ~isfield(DF.ax, axField), continue; end
                    nAx  = numel(DF.ax.(axField));
                    sIdx = 1:nAx;
                    % Co-indexed metadata axes (dim=[], e.g. per-unit 'chans')
                    % are NOT independently selectable — their values line up
                    % 1:1 with the traces. Subsetting them by their own Pointer
                    % selection (defaults to a single index) would collapse every
                    % trace to one colour and trip the unique() guard below, so
                    % only subset axes that own an array dimension. DF may be a
                    % nexObj_DF handle or a struct; DF.ptr likewise — guard both.
                    isMeta = false;
                    ptrObj = [];
                    try, ptrObj = DF.ptr; catch, end
                    if ~isempty(ptrObj)
                        hasK = (isstruct(ptrObj) && isfield(ptrObj, axField)) ...
                            || (~isstruct(ptrObj) && isprop(ptrObj, axField));
                        if hasK
                            pd = ptrObj.(axField);
                            isMeta = isstruct(pd) && isfield(pd, 'dim') && isempty(pd.dim);
                        end
                    end
                    if ~isMeta && ~isempty(ptrBus) && isfield(ptrBus.selections, axField)
                        s = ptrBus.selections.(axField);
                        s = sort(s(s >= 1 & s <= nAx));
                        if ~isempty(s), sIdx = s; end
                    end
                    axVals = string(DF.ax.(axField)(sIdx));
                    vals   = axVals(min((1:nTraces)', numel(axVals)));
                    if numel(unique(vals)) <= 1, continue; end
                    [C_ci, ~] = nexOp_resolveGroupColors(nexObj.nexon, axField, vals);
                    if isempty(labels), labels = vals; end
                else
                    % ── Group-column layer (broadcast to all traces) ──────
                    if ~ismember(key, grpCols), continue; end
                    rowVal    = string(rowTable.(key));
                    [C_ci, ~] = nexOp_resolveGroupColors(nexObj.nexon, key, rowVal);
                    C_ci      = repmat(C_ci, nTraces, 1);
                end
                all_C{end+1} = C_ci; %#ok<AGROW>
            end

            % Average all contributing layers; normalise each row so the
            % brightest channel reaches 1 (keeps blended colours vivid).
            if ~isempty(all_C)
                C    = mean(cat(3, all_C{:}), 3);
                maxC = max(C, [], 2);
                maxC(maxC < eps) = 1;
                C    = C ./ maxC;
            end
        end

        function [C, labels] = resolveAxColors(nexObj, DF, axField, nTraces)
            % Convenience wrapper: resolve per-trace colors for a single ax-- key.
            [C, labels] = nexObj.resolveCLRColors(DF, "ax--" + string(axField), nTraces);
        end

        function [rowBaseColors, axClrCols] = splitResultsColors(nexObj, RESULT, rowIdx, clrCols)
            % Pre-compute group-level base colors for a RESULTS rendering loop.
            %
            % Splits clrCols into ax-- keys (per-trace, handled inside the loop)
            % and group-column keys (need all rows at once for a correct hue spread).
            % rowBaseColors is [] when no group-column CLR keys are active.
            axClrCols  = clrCols(startsWith(clrCols, "ax--"));
            grpClrCols = clrCols(~startsWith(clrCols, "ax--"));
            if ~isempty(grpClrCols)
                rowBaseColors = nexObj.resolveGroupColors(RESULT(rowIdx,:), grpClrCols);
            else
                rowBaseColors = [];
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

        function refreshPointer(nexObj)
        % Refresh collector.Pointer listboxes from DF_postOp.ax, PRESERVING
        % existing selections where possible instead of resetting to
        % "select all" — mirrors mdlObject.refreshPointer/refreshPointerAxes_
        % (see Analysis/mdlObj/mdlObject.m). Requires collector.Pointer to
        % already exist (built once via initPointerBus); a genuinely first
        % build still goes through initPointerBus, which has no selections
        % to preserve yet anyway.
            if ~isfield(nexObj.collector, 'Pointer') || isempty(nexObj.collector.Pointer)
                return;
            end
            try
                newAx = nexObj.DF_postOp.ax;
            catch
                return;
            end
            nexObj.refreshPointerAxes_(newAx);
        end

        function refreshPointerAxes_(nexObj, newAx)
        % Shared remap-or-select-all logic behind refreshPointer: for each
        % axis field newAx shares with collector.Pointer, remap the current
        % selection onto the new values (by numeric range) when both old
        % and new are numeric, else fall back to "select all" (this
        % codebase's established no-op/pass-through convention). Ported
        % verbatim from mdlObject.refreshPointerAxes_ — same bus shape,
        % same problem (switching SRC/result shouldn't silently wipe a
        % Pointer subselection the user made to compare results by eye).
            if ~isfield(nexObj.collector, 'Pointer') || isempty(nexObj.collector.Pointer)
                return;
            end
            bus = nexObj.collector.Pointer;
            axFields = fieldnames(newAx);
            axFields = axFields(~strcmp(axFields, 'latent'));
            for i = 1:numel(axFields)
                ax = axFields{i};
                if ~isfield(bus.selKeys, ax), continue; end
                newVals = newAx.(ax);
                oldVals = bus.selKeys.(ax);
                if isequal(newVals, oldVals), continue; end
                nVals    = numel(newVals);
                curSel   = bus.selections.(ax);
                validSel = curSel(curSel >= 1 & curSel <= numel(oldVals));
                if ~isempty(validSel) && isnumeric(oldVals) && isnumeric(newVals)
                    selRange = oldVals(validSel);
                    newSel   = find(newVals >= min(selRange) & newVals <= max(selRange));
                else
                    newSel = [];
                end
                if isempty(newSel), newSel = 1:nVals; end
                bus.selKeys.(ax)    = newVals;
                bus.selections.(ax) = newSel;
                lb = [];
                if isfield(bus.listBoxes, ax), lb = bus.listBoxes.(ax); end
                if ~isempty(lb) && isvalid(lb)
                    lb.String = newVals;
                    lb.Max    = nVals;
                    lb.Value  = newSel;
                end
            end
        end

        function remodelDomain(nexObj, newAx)
        % Live-repoint this object's Domain and Pointer buses to a
        % genuinely DIFFERENT axis shape (e.g. switching which array a
        % RESULTS row's viewer looks at — df vs W, or any future
        % dfID_source swap) — without tearing down the object or its
        % figure. Distinct from refreshPointerAxes_/refreshPointer, which
        % assume the axis SET stays fixed and only values shifted (a pMap
        % edit) — those skip any field that doesn't already exist. This
        % handles fields being added AND dropped, which that guard was
        % never meant to do.
        %
        % Mutates collector.Domain/collector.Pointer's own .selKeys/
        % .selections STRUCT PROPERTIES in place — never reassigns the
        % bus OBJECTS themselves. nexObj_selectionBus is a handle class
        % with selKeys/selections as ordinary (non-dynamicprops)
        % properties (verified directly), so this is a safe, normal
        % property write — but reassigning the BUS OBJECT wholesale
        % (e.g. via buildSelection) would silently orphan any already-
        % built listbox's callback closure, which captured the ORIGINAL
        % bus object by reference (nexObj_listCfgPanel's
        % @(src,event)listCfgEntryChanged(src,event,key,selectionBus)) —
        % same risk already documented elsewhere in this codebase for
        % cfg.fitCfg reassignment. selections is SetObservable, so this
        % correctly fires any already-wired PostSet listeners too.
        %
        % Pointer's WIDGET PANEL still needs a real rebuild after this
        % call — the axis FIELD SET changed, not just values, so the
        % number/identity of listboxes genuinely changes (unlike Domain,
        % below, where the widget COUNT is fixed and only options change,
        % so this method updates those widgets directly). That rebuild is
        % left to the caller since panel layout is subclass-specific
        % (e.g. nexObj_bar's own split outer/inner panel construction).
            axisKeys = string(fieldnames(newAx))';
            axisKeys = axisKeys(axisKeys ~= "latent");
            if isempty(axisKeys), return; end

            % ── Pointer: bus data only (widgets rebuilt by caller) ──────────
            if isfield(nexObj.collector, 'Pointer') && ~isempty(nexObj.collector.Pointer)
                bus           = nexObj.collector.Pointer;
                oldSelKeys    = bus.selKeys;
                oldSelections = bus.selections;
                newSelKeys    = struct();
                newSelections = struct();
                for i = 1:numel(axisKeys)
                    f    = char(axisKeys(i));
                    vals = newAx.(f);
                    if isempty(vals), continue; end
                    newSelKeys.(f) = vals;
                    % Preserve by name + remap-by-value-range where the
                    % field already existed (same convention
                    % refreshPointerAxes_ uses), else fresh SINGLE-ITEM
                    % default (index 1) — buildSelection's own true
                    % default (initSel=1), matching initPointerBus's own
                    % "single-item default = pass-through" convention. NOT
                    % select-all: a brand-new field (e.g. fold/perm, never
                    % in the construction-time placeholder bus) left fully
                    % multi-selected never reduces to a singleton, so
                    % nexOp_sliceAndCollapse can never collapse it down to
                    % a 2D surface — every axis besides the 2 chosen for
                    % D1 and the 1 for ANI has to land on exactly one
                    % value for the canvas to render at all.
                    newSel = 1;
                    if isfield(oldSelKeys, f)
                        oldVals  = oldSelKeys.(f);
                        curSel   = oldSelections.(f);
                        validSel = curSel(curSel >= 1 & curSel <= numel(oldVals));
                        if ~isempty(validSel) && isnumeric(oldVals) && isnumeric(vals)
                            selRange = oldVals(validSel);
                            remapped = find(vals >= min(selRange) & vals <= max(selRange));
                            if ~isempty(remapped), newSel = remapped; end
                        end
                    end
                    newSelections.(f) = newSel;
                end
                bus.selKeys    = newSelKeys;
                bus.selections = newSelections;
            end

            % ── Domain: bus data AND widgets (widget count is fixed — ───────
            % D1/ANI/etc. stay the same keys, only their OPTIONS change,
            % so a direct .String/.Value update suffices here, generic
            % over whatever Domain keys this subclass actually has. REG is
            % deliberately excluded from this generic pass — its candidate
            % list is "None" + co-indexed siblings (nexOp_computeREGOptions),
            % not the plain full axis list every other Domain key here
            % wants; it's refreshed separately, below, via refreshREG().
            if isfield(nexObj.collector, 'Domain') && ~isempty(nexObj.collector.Domain)
                bus     = nexObj.collector.Domain;
                domKeys = fieldnames(bus.selKeys);
                domKeys = domKeys(~strcmp(domKeys, 'REG'));
                for i = 1:numel(domKeys)
                    dk = domKeys{i};
                    % Reference for "what should still be selected" is the
                    % CURRENT live selection's own names — not the static
                    % construction-time domain.(dk) struct, which reflects
                    % the ORIGINAL raw DF and rarely means anything for
                    % either side of a repoint. Same fallback SHAPE as
                    % construction-time seeding otherwise: try a name
                    % match, else the bare single-item default (matching
                    % buildSelection's own default) if nothing carries over.
                    try
                        prevNames = string(bus.selKeys.(dk)(bus.selections.(dk)));
                    catch
                        prevNames = string.empty(1,0);
                    end
                    keepIdx = find(ismember(axisKeys, prevNames));
                    if isempty(keepIdx), keepIdx = 1; end
                    bus.selKeys.(dk)    = axisKeys;
                    bus.selections.(dk) = keepIdx;
                    if isfield(bus.listBoxes, dk) && ~isempty(bus.listBoxes.(dk)) ...
                            && isvalid(bus.listBoxes.(dk))
                        lb = bus.listBoxes.(dk);
                        lb.String = cellstr(axisKeys);
                        lb.Value  = keepIdx;
                    end
                end
            end

            % ── CLR: ax-- keys refreshed to match the new axis shape ────────
            % Same "ax--" + fieldnames(...) construction initCollectorView
            % already uses at construction time — just triggered here
            % instead, since DF_postOp.ax isn't known yet at construction
            % for a source-watching nexObject (same reason Domain/Pointer,
            % above, need this method rather than construction-time-only
            % seeding). refreshCLR() alone can't do this on its own: it only
            % PRESERVES whatever ax-- keys already exist and never adds or
            % drops any — the same "axis fields added AND dropped" gap this
            % method already exists to fix for Pointer/Domain. Group-column
            % keys (from RESULTS tables) are left for refreshCLR's own,
            % already-correct merge/selection-preservation logic rather
            % than duplicated here.
            if isfield(nexObj.collector, 'View') && ~isempty(nexObj.collector.View) ...
                    && ismethod(nexObj, 'refreshCLR')
                bus      = nexObj.collector.View;
                existing = string(bus.selKeys.CLR);
                grpKeys  = existing(existing ~= "" & ~startsWith(existing, "ax--"));
                bus.selKeys.CLR = [grpKeys(:); ("ax--" + axisKeys)'];
                nexObj.refreshCLR();
            end

            % ── REG: candidates recomputed from the new axis set ────────────
            % Excluded from the generic Domain loop above for the reason
            % noted there; refreshREG() derives the correct "None" +
            % co-indexed-siblings candidate list instead of the plain axis
            % list. No-op if this subclass never added a REG key at all.
            if ismethod(nexObj, 'refreshREG')
                nexObj.refreshREG();
            end
        end

        % ── Selection import / export ──────────────────────────────────────

        function exportSelection(nexObj, busID, varName)
            % Save selected values from collector.(busID) to the base workspace.
            % Stores VALUES not indices so the result is portable across nexObjects
            % whose axes may differ in length or ordering.
            if nargin < 3 || isempty(varName)
                varName = sprintf('sel_%s_%s', nexObj.classID, busID);
            end
            if ~isfield(nexObj.collector, busID)
                fprintf('[exportSelection] collector.%s not found on %s.\n', busID, class(nexObj));
                return;
            end
            bus = nexObj.collector.(busID);
            if isempty(bus), return; end

            sel.busID = busID;
            sel.keys  = fieldnames(bus.selections);
            sel.values = struct();
            for k = 1:numel(sel.keys)
                key = sel.keys{k};
                idx = bus.selections.(key);
                nK  = numel(bus.selKeys.(key));
                idx = sort(idx(idx >= 1 & idx <= nK));
                if isempty(idx)
                    sel.values.(key) = bus.selKeys.(key)(ones(1,0));  % empty, same type
                else
                    sel.values.(key) = bus.selKeys.(key)(idx);
                end
            end
            assignin('base', varName, sel);
            fprintf('[exportSelection] %s.collector.%s → base.%s\n', class(nexObj), busID, varName);
        end

        function importSelection(nexObj, sel)
            % Apply a saved selection struct (from exportSelection) to this object.
            % Matches by value — keys or values absent from this bus are skipped
            % gracefully rather than erroring.
            if ~isstruct(sel) || ~isfield(sel, 'busID') || ~isfield(sel, 'keys')
                warning('[importSelection] Invalid selection struct.');
                return;
            end
            if ~isfield(nexObj.collector, sel.busID)
                fprintf('[importSelection] collector.%s not found on %s — skipping.\n', sel.busID, class(nexObj));
                return;
            end
            bus = nexObj.collector.(sel.busID);
            if isempty(bus), return; end

            for k = 1:numel(sel.keys)
                key = sel.keys{k};
                if ~isfield(bus.selections, key), continue; end
                if ~isfield(sel.values, key),     continue; end

                savedVals = sel.values.(key);
                allVals   = bus.selKeys.(key);

                % Match saved values into current axis — numeric uses tolerance
                if isnumeric(savedVals) && isnumeric(allVals)
                    sc = max(abs(double(allVals(:))));
                    if sc == 0, sc = 1; end
                    [tf, loc] = ismembertol(double(savedVals(:)), double(allVals(:)), 1e-9, 'DataScale', sc);
                else
                    [tf, loc] = ismember(string(savedVals(:)), string(allVals(:)));
                end
                newSel = sort(loc(tf & loc > 0))';
                if isempty(newSel), continue; end  % no overlap — leave as-is

                bus.selections.(key) = newSel;
                if isfield(bus.listBoxes, key)
                    lb = bus.listBoxes.(key);
                    if ~isempty(lb) && isvalid(lb)
                        lb.Value = newSel;
                    end
                end
            end

            if ismethod(nexObj, 'visualize')
                nexObj.visualize();
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

        function rebuildPointerPanel(nexObj)
        % Delete and rebuild pointer controls inside Figure.panel_pointer
        % — the container buildPointerPanel (above) stores its
        % nexObj_listCfgPanel instance in. Companion to that method: this
        % is what applySRC calls after remodelDomain changes the axis
        % SET (not just values), since the widget count/identity itself
        % needs to change, not just String/Value on existing widgets.
        % Subclasses with a different panel-container convention (e.g.
        % nexObj_bar's own split outer/inner panel, built to protect a
        % sibling control from this method's own child-delete) override
        % this instead of using the base version.
            if ~isfield(nexObj.Figure, 'panel_pointer') || isempty(nexObj.Figure.panel_pointer)
                return;
            end
            ph = nexObj.Figure.panel_pointer.ph;
            if isempty(ph) || ~isvalid(ph), return; end
            delete(ph.Children);
            if isempty(nexObj.collector.Pointer) || isempty(nexObj.nexon), return; end
            try
                nexObj.Figure.panel_pointer = nexObj_listCfgPanel( ...
                    nexObj.nexon, struct('ph', ph), nexObj.collector.Pointer, []);
            catch
            end
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
            % Display-time event alignment: relabel the (trigger-relative) time
            % axis so 0 lands on the event chosen in the SLRT eventAlignment
            % selection (e.g. stimOnsetAdvance). Non-destructive; no-op when
            % there's no selection or the DF has no t axis. Applied before
            % operate() so the pointer/axis pick up the aligned ax_t.
            try
                nexObj.DF = nexOp_eventAlignBySelection(nexObj.nexon, nexObj.DF, []);
            catch e
                disp(getReport(e));
            end
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

    methods (Static)
        function [nexon_, source] = resolveNexonFromSource(source)
        % Extracted verbatim from nexObj_bar's own constructor (which
        % originated this pattern) — generic across any nexObject
        % subclass wanting to be constructed FROM a live model/data
        % source (an mdlObj today, anything nexon-bearing later) rather
        % than a categorical Parent or bare dfID. Runs BEFORE
        % obj@nexObject(...) — no instance exists yet at that point, so
        % this can't be a regular instance method. Pair with the
        % instance method wireModelSource, called right after the
        % superclass constructor, for the rest of the wiring (Partners,
        % lazy RESULTS stubs) that DOES need a live nexObj to attach to.
            if isempty(source)
                nexon_ = [];
            elseif isprop(source, 'nexon') || isfield(source, 'nexon')
                nexon_ = source.nexon;
            elseif isa(source, 'Nexon')
                nexon_ = source; source = [];
            else
                nexon_ = [];
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