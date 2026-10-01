classdef nexObj_monoGram < nexObject
    % nexObj_monoGram  2-D surf visualization (spectrogram, TF, heatmap).
    %
    % Domain convention (monoGram-specific):
    %   D1       — two display axes shown as surf rows × cols (e.g. [f, t])
    %   animate  — animation axis stepped by the player (e.g. chans)
    %   (no D2 in the waterfall sense; ANI is the only non-display axis)
    %
    % Collectors populated at construction:
    %   collector.View    — SRC / VW / CLR  (via initCollectorView)
    %   collector.Domain  — D1 (multi-select, 2 items) / ANI (single-select)
    %   collector.Pointer — per-axis value filter (via initPointerBus)
    %
    % Constructor
    %   nexObj_monoGram(nexon, Parent, dfID_source, opCfgFcn, domain, headline)

    properties
    end

    methods

        % ── Constructor ───────────────────────────────────────────────────
        function nexObj = nexObj_monoGram(nexon, Parent, dfID_source, opCfgFcn, domain, headline)
            if nargin < 6, headline = []; end
            if nargin < 5, domain   = []; end

            % mdlObj-sourced construction — watches a live mdlObject's
            % RESULTS directly (accuracy/weights facets), bypassing the
            % categorical-hub DF/DTS pull entirely. Parallel to
            % nexObj_bar's own source-watching constructor path; see
            % nexObject.resolveNexonFromSource/wireModelSource. Args to
            % the (unconditional — MATLAB disallows a conditionalized
            % superclass constructor call) obj@nexObject(...) call below
            % are resolved here; the rest of this branch's setup runs
            % after that call, ending in an early return.
            isMdlSource = ~isempty(Parent) && isa(Parent, 'mdlObject');
            if isMdlSource
                if isempty(headline), headline = 'monoGram'; end
                [nexon, source] = nexObject.resolveNexonFromSource(Parent);
                Parent      = [];
                dfID_source = "";
            elseif ~isempty(Parent)
                nexon = Parent.nexon;
            end

            nexObj = nexObj@nexObject(nexon, Parent, dfID_source, headline);
            nexObj.classID = "mgm";

            if isMdlSource
                % No DTS pull — seed empty DF_postOp, mirrors nexObj_bar.
                nexObj.DF_postOp = struct('df', [], 'ax', struct(), 'ptr', struct());
                % nexObj.pMap is never populated on this path (no
                % nexInit_pMap call — there's no DF to pool yet). Must be a
                % real (if empty-fieldnames) struct, not the property's
                % default [] — nexFigure_monoGram unconditionally builds a
                % pool panel via nexObj_poolCfgPanel_v2, which falls back to
                % nexObj.pMap and calls fieldnames(pMap) on it with no
                % isstruct guard; fieldnames([]) errors outright (wrong
                % type), unlike fieldnames(struct()) which cleanly yields
                % an empty list.
                nexObj.pMap = struct();

                nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_monoGram"));
                nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexObject.stepAnimate"));

                % View bus: SRC = result IDs (+ weights facet via
                % refreshSRC/applySRC), VW = row filter, CLR = empty — same
                % shape nexObj_bar uses; no CTG (monoGram has no
                % categorical grouping concept of its own).
                viewDict.SRC = "";
                viewDict.CTG = "";
                viewDict.VW  = "";
                viewDict.CLR = "";
                nexObj.collector.View = nexInit_collectorView(nexObj, viewDict);

                % Domain/Pointer seeded with placeholder single-item keys —
                % genuinely populated once a RESULTS row is selected via
                % applySRC -> remodelDomain, which only MUTATES an
                % already-live bus object and never builds one from
                % scratch (see remodelDomain's own header comment). Fully
                % overwritten on first real selection; same fallback shape
                % construction-time seeding uses elsewhere in this class.
                domainDict.D1  = "";
                domainDict.ANI = "";
                domainDict.REG = "None";
                nexObj.collector.Domain  = buildSelection(nexObj, domainDict);
                nexObj.collector.Pointer = buildSelection(nexObj, struct('placeholder', ""));

                nexObj.wireModelSource(source);

                isHeadless = ~isempty(nexon) && isfield(nexon, 'settings') && ...
                             isfield(nexon.settings, 'headless') && nexon.settings.headless;
                if ~isHeadless
                    nexObj.buildFigure();
                    nexObj.player = timer('Period', 0.2, 'BusyMode', 'drop', ...
                        'ExecutionMode', 'fixedRate', ...
                        'TimerFcn', @(~,~) nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams));
                    if isstruct(nexObj.RESULTS) && ~isempty(fieldnames(nexObj.RESULTS))
                        nexObj.refreshSRC();
                    end
                end
                return;
            end

            %% DF loading
            if ~isempty(Parent)
                nexObj.DF     = Parent.DF_postOp;
                nexObj.Origin = Parent.Origin;
                nexObj.Parent.Children.(nexObj.classID) = nexObj;
            elseif ~isempty(dfID_source)
                nexObj.DF     = dtsIO_readDF(nexObj.nexon, dfID_source, []);
                nexObj.Origin = nexObj;
            end

            %% Config
            nexObj.cfg.opCfg  = [];
            if nargin >= 4 && ~isempty(opCfgFcn)
                nexObj.cfg.opCfg = nex_generateCfgObj(opCfgFcn);
            end
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_monoGram"));
            nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexObject.stepAnimate"));

            %% Operate → DF_postOp (preserves ptr handle across re-operates)
            nexObj.operate();

            %% Pool map
            try
                nexObj.pMap = nexInit_pMap(nexObj, nexObj.DF_postOp);
            catch e
                disp(getReport(e));
            end

            %% Domain (infer or accept override)
            if ~isempty(domain)
                nexObj.domain = domain;
            else
                nexObj.domain = nexObj.inferDomain();
            end

            %% Collector — View (SRC / VW / CLR with ax-- keys)
            nexObj.initCollectorView();

            %% Collector — Domain (D1 = two display axes, ANI = animation axis,
            % REG = cross-sample registration identity axis — consumed by
            % nexOp_compileSTAT's co-axis alignment; see nexObject.refreshREG)
            axisKeys = string(fieldnames(nexObj.DF_postOp.ax))';
            if isempty(axisKeys), axisKeys = ""; end
            domainDict.D1  = axisKeys;
            domainDict.ANI = axisKeys;
            domainDict.REG = nexOp_computeREGOptions(axisKeys, nexObj.DF_postOp.ax);
            nexObj.collector.Domain = buildSelection(nexObj, domainDict);
            nexObj.collector.Domain.selections.REG = 1;   % default = "None"

            % Seed selections from inferred domain
            if ~isequal(axisKeys, "")
                d1Sel = [];
                for di = 1:min(2, numel(nexObj.domain.D1))
                    idx = find(axisKeys == string(nexObj.domain.D1(di)), 1);
                    if ~isempty(idx), d1Sel(end+1) = idx; end %#ok<AGROW>
                end
                if ~isempty(d1Sel)
                    nexObj.collector.Domain.selections.D1 = d1Sel;
                end
                if ~isempty(nexObj.domain.animate) && ~isequal(string(nexObj.domain.animate), "")
                    aniIdx = find(axisKeys == string(nexObj.domain.animate), 1);
                    if ~isempty(aniIdx)
                        nexObj.collector.Domain.selections.ANI = aniIdx;
                    end
                end
            end

            %% Collector — Pointer (one key per DF.ax field)
            nexObj.initPointerBus();
            % Free the default animate axis's Pointer selection so its frame is
            % driven by ptr.value (stepAnimate) rather than pinned to the default
            % single index — otherwise the player advances an ignored value and
            % the frame never changes.
            nexObj.clearAnimatePointer();

            %% Figure
            nexObj.buildFigure();

            %% Animation player
            nexObj.player = timer('Period', 0.2, 'BusyMode', 'drop', ...
                'ExecutionMode', 'fixedRate', ...
                'TimerFcn', @(~,~) nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams));
        end

        % ── Core pipeline ─────────────────────────────────────────────────

        function operate(nexObj)
            % Apply opCfg (or identity), preserving the ptr handle reference
            % so UI callbacks bound at figure-build time remain valid.
            % isstruct() is intentionally avoided: DF_postOp can be a nexObj_DF
            % handle when the parent assigns its DF_postOp directly, making
            % isstruct() return false and triggering a new ptr — severing all
            % Window/Pointer UI closures that captured the original handle.
            savedPtr = [];
            try
                p = nexObj.DF_postOp.ptr;
                if isa(p, 'nexObj_ptr'), savedPtr = p; end
            catch
            end

            % Snapshot valid df+ax before replacement so we can fall back
            % if the incoming DF is transiently empty (e.g. a router update
            % fires mid-capture before data has arrived).
            prevDF = []; prevAX = [];
            try
                if ~isempty(nexObj.DF_postOp) && ~isempty(nexObj.DF_postOp.df)
                    prevDF = nexObj.DF_postOp.df;
                    prevAX = nexObj.DF_postOp.ax;
                end
            catch
            end

            if ~isempty(nexObj.cfg.opCfg)
                opArgs           = nexObj.cfg.opCfg.entryParams;
                nexObj.DF_postOp = nexObj.cfg.opCfg.opFcn(nexObj.DF, opArgs);
            else
                nexObj.DF_postOp = nexObj.DF;
            end

            % If DF_postOp is still a handle (e.g. Parent.DF_postOp is a
            % nexObj_DF), extract df+ax into a plain struct so we own our
            % own copy.  Without this, the Parent's next operate() would
            % overwrite .ptr on the shared handle, severing our UI closures.
            if ~isstruct(nexObj.DF_postOp)
                try
                    s.df = nexObj.DF_postOp.df;
                    s.ax = nexObj.DF_postOp.ax;
                    nexObj.DF_postOp = s;
                catch
                end
            end

            % If the new DF is empty but we had valid data, restore the
            % previous df+ax so the animation continues uninterrupted.
            if ~isempty(prevDF) && isempty(nexObj.DF_postOp.df)
                nexObj.DF_postOp.df = prevDF;
                nexObj.DF_postOp.ax = prevAX;
            end

            if ~isempty(savedPtr)
                nex_updateAxisPointer(savedPtr, nexObj.DF_postOp);
                nexObj.DF_postOp.ptr = savedPtr;
            else
                nexObj.DF_postOp.ptr = nexInit_axisPointer( ...
                    nexObj.DF_postOp.df, nexObj.DF_postOp.ax);
            end
        end

        function updateScope(nexObj)
            if ~isempty(nexObj.Parent)
                nexObj.DF = nexObj.Parent.DF_postOp;
            end
            nexObj.operate();
            nexObj.visualize();
        end

        function buildFigure(nexObj)
            nexFigure_monoGram(nexObj);
        end

        function visualize(nexObj)
            nexVisualization_monoGram(nexObj, nexObj.cfg.visCfg.entryParams);
        end

        function homeLimits(nexObj)
        % "Home" — set zLim/cLim to the CURRENTLY RENDERED surface's actual
        % data range (min/max of the live canvas's ZData, NaN/Inf ignored),
        % mirroring MATLAB's own axis-reset icon: entryParams is never
        % touched by an ordinary visualize() call (only by a direct
        % spinner edit or this method), so a manual zLim/cLim edit persists
        % across re-visualizes exactly as before — this is purely an
        % explicit "go find the real range for me" action, not something
        % that runs automatically on every frame (would fight a manual
        % override the user just made, and would jitter the scale on every
        % animation step).
        %
        % Reads ZData off the live canvas rather than re-deriving/re-
        % slicing DF_src itself — nexVisualization_monoGram already wrote
        % the exact post-transform Z there this call, so this is a single
        % source of truth instead of a second slicing path that could
        % drift out of sync with it.
            try
                canvas = nexObj.Figure.panel0.tiles.graphics.canvas;
            catch
                return;
            end
            if isempty(canvas) || ~isvalid(canvas), return; end
            Z = double(canvas.ZData);
            Z = Z(isfinite(Z));
            if isempty(Z), return; end
            zLo = min(Z); zHi = max(Z);
            if zLo == zHi
                % Degenerate (single-valued) surface — MATLAB rejects a
                % zero-span ZLim/CLim outright, so pad a bit either way.
                zLo = zLo - 0.5; zHi = zHi + 0.5;
            else
                % Pad by 5% of the span each way rather than capping
                % exactly at the data extrema — a peak/trough sitting
                % right on the boundary reads as clipped/cut-off
                % otherwise, especially on a colorbar.
                padFrac = 0.05;
                pad     = padFrac * (zHi - zLo);
                zLo = zLo - pad; zHi = zHi + pad;
            end

            ep = nexObj.cfg.visCfg.entryParams;
            ep.zLim_low  = zLo;  ep.zLim_high  = zHi;
            ep.cLim_low  = zLo;  ep.cLim_high  = zHi;
            nexObj.cfg.visCfg.entryParams = ep;   % cfgObj is a handle — in-place mutation

            % Sync the Vis cfg panel's own spinners — they only push
            % UI->entryParams (cfgEntryChanged_v2), never the reverse, so
            % without this the spinners would silently disagree with what
            % just got applied.
            try
                ef = nexObj.Figure.panel_vis.editFields;
                for f = ["zLim_low", "zLim_high", "cLim_low", "cLim_high"]
                    if isfield(ef, f) && isvalid(ef.(f).uiField)
                        ef.(f).uiField.Value = ep.(f);
                    end
                end
            catch
            end

            nexObj.visualize();
        end

        % refreshSRC / applySRC / rebuildPointerPanel: no override needed —
        % monoGram uses the base nexObject versions directly (promoted
        % there since every OTHER current subclass already has its own
        % override, making this a zero-risk place for the shared,
        % facet-aware (accuracy/weights) logic to live — see nexObject.m).

    end
end
